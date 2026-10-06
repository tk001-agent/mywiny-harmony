import { RawDialog, TopicNode, ProjectNode, ConflictRecord, ConflictSolution, EvolutionSummary,
  MetaInfo, TreeData, SnapshotType } from '../model/DataTypes';
import { RawStorage } from '../storage/RawStorage';
import { TreeStorage } from '../storage/TreeStorage';
import { MetaStorage } from '../storage/MetaStorage';
import { ParadigmStorage } from '../storage/ParadigmStorage';
import { SnapshotManager } from '../storage/SnapshotManager';
import { IdGenerator } from '../storage/IdGenerator';
import { ConfigManager } from '../storage/ConfigManager';
import { FileUtil } from '../storage/FileUtil';
import { ModelClient } from './ModelClient';
import { ParadigmRunner, ParadigmResult } from './ParadigmRunner';
import { MetaChecker, CheckResult } from './MetaChecker';
import { ConflictManager } from './ConflictManager';
import { ResidentLayer } from './ResidentLayer';
import { Constants } from '../common/Constants';

export type ProgressCallback = (step: number, total: number, message: string) => void;

export class EvolutionEngine {
  private rawStorage: RawStorage;
  private treeStorage: TreeStorage;
  private metaStorage: MetaStorage;
  private paradigmStorage: ParadigmStorage;
  private snapshotManager: SnapshotManager;
  private idGen: IdGenerator;
  private configManager: ConfigManager;
  private modelClient: ModelClient;
  private paradigmRunner: ParadigmRunner;
  private metaChecker: MetaChecker;
  private conflictManager: ConflictManager;
  private residentLayer: ResidentLayer;

  constructor(rawStorage: RawStorage, treeStorage: TreeStorage, metaStorage: MetaStorage,
    paradigmStorage: ParadigmStorage, snapshotManager: SnapshotManager, idGen: IdGenerator,
    configManager: ConfigManager, modelClient: ModelClient) {
    this.rawStorage = rawStorage;
    this.treeStorage = treeStorage;
    this.metaStorage = metaStorage;
    this.paradigmStorage = paradigmStorage;
    this.snapshotManager = snapshotManager;
    this.idGen = idGen;
    this.configManager = configManager;
    this.modelClient = modelClient;
    this.paradigmRunner = new ParadigmRunner(modelClient, idGen);
    this.metaChecker = new MetaChecker(modelClient);
    this.conflictManager = new ConflictManager(modelClient, treeStorage);
    this.residentLayer = new ResidentLayer(modelClient);
  }

  hasNewDialogs(): boolean {
    let lastTime = this.metaStorage.readLastEvolutionTime();
    let latest = this.rawStorage.getLastDialogTime();
    return latest > lastTime;
  }

  async evolve(progress?: ProgressCallback): Promise<EvolutionSummary> {
    let lastTime = this.metaStorage.readLastEvolutionTime();
    let allDialogs = this.rawStorage.listDialogs();
    let newDialogs: RawDialog[] = [];
    for (let i = 0; i < allDialogs.length; i++) {
      if (allDialogs[i].timestamp > lastTime) {
        newDialogs.push(allDialogs[i]);
      }
    }
    if (newDialogs.length === 0) {
      return this.noNewDialogResult();
    }
    return this.runPipeline(newDialogs, 'inc', progress);
  }

  async deepEvolve(progress?: ProgressCallback): Promise<EvolutionSummary> {
    let allDialogs = this.rawStorage.listDialogs();
    return this.runPipeline(allDialogs, 'deep', progress);
  }

  private async runPipeline(dialogs: RawDialog[], mode: SnapshotType,
    progress?: ProgressCallback): Promise<EvolutionSummary> {
    let totalSteps = 10;
    let step = 0;
    let startTime = FileUtil.getTimestamp();
    let p = (msg: string): void => {
      step++;
      if (progress !== undefined) {
        progress(step, totalSteps, msg);
      }
    };

    try {
      p('读取话题树、项目树、思考范式与元理解');
      let treeData = this.treeStorage.readTreeData();
      let paradigmText = this.paradigmStorage.readParadigm();
      let metaCurrent = this.metaStorage.readMetaCurrent();
      let metaBase = this.metaStorage.readMetaBase();

      p('执行8大核心模型思考分析');
      let isDeep = mode === 'deep';
      let result = await this.paradigmRunner.run(dialogs, treeData, paradigmText,
        metaCurrent.content, isDeep);

      p('更新话题树与项目树');
      let updatedTopics = this.applyTopics(treeData.topics, result, isDeep);
      let updatedProjects = this.applyProjects(treeData.projects, result);
      this.treeStorage.writeTopicTree(updatedTopics);
      this.treeStorage.writeProjectTree(updatedProjects);
      this.writeChangelogs(result, isDeep);

      p('处理冲突与生成调和方案');
      let conflictCount = await this.processConflicts(result.conflicts);

      p('元理解迭代与 meta_base 基准自检');
      let metaCheckOk = await this.updateMetaCurrent(result, metaBase, metaCurrent);

      p('生成快照');
      let snapshotId = this.snapshotManager.createSnapshot(mode, this.buildSnapshotNote(result, mode));

      p('快照分级清理');
      let cfg = this.configManager.getConfig();
      this.snapshotManager.cleanup(cfg.incRetainCount, 'inc');
      this.snapshotManager.cleanup(cfg.deepRetainCount, 'deep');

      p('压缩刷新常驻层');
      await this.refreshResidentLayer(updatedTopics, updatedProjects, cfg.residentLayerMaxChars);

      p('更新时间戳与运行日志');
      let endTime = FileUtil.getTimestamp();
      this.metaStorage.writeLastEvolutionTime(endTime);
      this.writeRunLog(result, mode, startTime, endTime);

      let summary: EvolutionSummary = {
        mode: isDeep ? '深度进化' : '普通进化',
        newDialogCount: dialogs.length,
        newTopicCount: result.newTopics.length,
        newProjectCount: result.newProjects.length,
        conflictCount: conflictCount,
        snapshotId: snapshotId,
        duration: endTime - startTime,
        success: true,
        message: this.buildSummaryText(result, mode, conflictCount, endTime - startTime),
      };

      if (conflictCount >= Constants.CONFLICT_THRESHOLD && mode === 'inc') {
        summary.message += '\n⚠ 检出严重冲突(' + conflictCount + '个)，建议执行深度进化全盘重整。';
      }
      return summary;
    } catch (e) {
      let endTime = FileUtil.getTimestamp();
      this.metaStorage.appendAutorunlog('进化异常终止: ' + String(e));
      return {
        mode: mode === 'deep' ? '深度进化' : '普通进化',
        newDialogCount: dialogs.length,
        newTopicCount: 0,
        newProjectCount: 0,
        conflictCount: 0,
        snapshotId: '',
        duration: endTime - startTime,
        success: false,
        message: '进化失败: ' + String(e),
      };
    }
  }

  private applyTopics(existing: TopicNode[], result: ParadigmResult, isDeep: boolean): TopicNode[] {
    let topics = existing.slice();
    if (isDeep) {
      for (let i = 0; i < result.updatedTopics.length; i++) {
        let u = result.updatedTopics[i];
        let found = false;
        for (let j = 0; j < topics.length; j++) {
          if (topics[j].id === u.id) {
            if (u.title.length > 0) {
              topics[j].title = u.title;
            }
            if (u.refs.length > 0) {
              topics[j].refs = this.mergeRefs(topics[j].refs, u.refs);
            }
            if (u.description.length > 0) {
              topics[j].description = u.description;
            }
            found = true;
            break;
          }
        }
      }
    } else {
      for (let i = 0; i < result.updatedTopics.length; i++) {
        let u = result.updatedTopics[i];
        for (let j = 0; j < topics.length; j++) {
          if (topics[j].id === u.id) {
            topics[j].refs = this.mergeRefs(topics[j].refs, u.refs);
            break;
          }
        }
      }
    }
    for (let i = 0; i < result.newTopics.length; i++) {
      topics.push(result.newTopics[i]);
    }
    return topics;
  }

  private applyProjects(existing: ProjectNode[], result: ParadigmResult): ProjectNode[] {
    let projects = existing.slice();
    for (let i = 0; i < result.newProjects.length; i++) {
      projects.push(result.newProjects[i]);
    }
    return projects;
  }

  private mergeRefs(existing: string[], addition: string[]): string[] {
    let set = new Set<string>(existing);
    for (let i = 0; i < addition.length; i++) {
      set.add(addition[i]);
    }
    return Array.from(set);
  }

  private writeChangelogs(result: ParadigmResult, isDeep: boolean): void {
    for (let i = 0; i < result.newTopics.length; i++) {
      let t = result.newTopics[i];
      this.treeStorage.appendTopicChangelog('新增话题 ' + t.id + ' ' + t.title +
        ' ref:' + t.refs.join(','));
    }
    for (let i = 0; i < result.newProjects.length; i++) {
      let p = result.newProjects[i];
      this.treeStorage.appendProjectChangelog('新增项目 ' + p.id + ' ' + p.title +
        ' ref:' + p.refs.join(','));
    }
    for (let i = 0; i < result.changelogEntries.length; i++) {
      this.treeStorage.appendTopicChangelog(result.changelogEntries[i]);
    }
  }

  private async processConflicts(conflicts: ConflictRecord[]): Promise<number> {
    if (conflicts.length === 0) {
      return 0;
    }
    let count = 0;
    for (let i = 0; i < conflicts.length; i++) {
      let c = conflicts[i];
      c.id = this.idGen.nextConflictId();
      let solutions = await this.conflictManager.generateSolutions(c.description, c.refs);
      c.solutions = solutions;
      let chosen = this.conflictManager.selectSolution(solutions);
      c.chosenLabel = chosen.label;
      c.resolved = true;
      this.conflictManager.archiveConflict(c);
      count++;
    }
    return count;
  }

  private async updateMetaCurrent(result: ParadigmResult, metaBase: string,
    current: MetaInfo): Promise<boolean> {
    if (result.metaUpdateContent.length === 0) {
      return true;
    }
    let newContent = current.content + '\n' + result.metaUpdateContent;
    let checkResult: CheckResult = await this.metaChecker.check(newContent, metaBase);
    if (!checkResult.passed) {
      this.metaStorage.appendAutorunlog('元理解更新被拒绝: ' + checkResult.reason);
      return false;
    }
    let needReview = result.metaConfidence < Constants.META_CONFIDENCE_THRESHOLD;
    let newMeta: MetaInfo = {
      version: current.version + 1,
      content: newContent,
      confidence: result.metaConfidence,
      timestamp: FileUtil.getTimestamp(),
      needReview: needReview,
    };
    this.metaStorage.writeMetaCurrent(newMeta);
    this.metaStorage.appendMetaChangelog('版本' + newMeta.version + ' 置信度' +
      newMeta.confidence + (needReview ? ' [待人工复核]' : ''));
    if (needReview) {
      this.metaStorage.appendAutorunlog('元理解置信度' + result.metaConfidence +
        '%低于阈值，需人工复核');
    }
    return true;
  }

  private async refreshResidentLayer(topics: TopicNode[], projects: ProjectNode[],
    maxChars: number): Promise<void> {
    let content = await this.residentLayer.generate(topics, projects, maxChars);
    this.metaStorage.writeResidentLayer(content);
  }

  private writeRunLog(result: ParadigmResult, mode: SnapshotType, start: number, end: number): void {
    let sb = '=== ' + (mode === 'deep' ? '深度进化' : '普通进化') + ' ===\n';
    sb += '时间: ' + FileUtil.formatTime(start) + ' - ' + FileUtil.formatTime(end) + '\n';
    sb += '耗时: ' + (end - start) + 'ms\n';
    sb += '新增话题: ' + result.newTopics.length + '\n';
    sb += '新增项目: ' + result.newProjects.length + '\n';
    sb += '冲突: ' + result.conflicts.length + '\n';
    sb += '元理解置信度: ' + result.metaConfidence + '\n';
    this.metaStorage.appendAutorunlog(sb);
  }

  private buildSnapshotNote(result: ParadigmResult, mode: SnapshotType): string {
    return (mode === 'deep' ? '深度进化' : '普通进化') + ' | 新增话题' +
      result.newTopics.length + ' 新增项目' + result.newProjects.length +
      ' 冲突' + result.conflicts.length;
  }

  private buildSummaryText(result: ParadigmResult, mode: SnapshotType,
    conflictCount: number, duration: number): string {
    let sb = (mode === 'deep' ? '深度进化' : '普通进化') + '完成\n';
    sb += '新增话题: ' + result.newTopics.length + ' 个\n';
    sb += '新增项目: ' + result.newProjects.length + ' 个\n';
    sb += '冲突处理: ' + conflictCount + ' 个\n';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             