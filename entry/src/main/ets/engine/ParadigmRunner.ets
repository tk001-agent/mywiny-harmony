import { RawDialog, TopicNode, ProjectNode, ConflictRecord, TreeData, ModelMessage } from '../model/DataTypes';
import { ModelClient } from './ModelClient';
import { IdGenerator } from '../storage/IdGenerator';

export interface ParadigmResult {
  newTopics: TopicNode[];
  updatedTopics: TopicNode[];
  newProjects: ProjectNode[];
  conflicts: ConflictRecord[];
  metaUpdateContent: string;
  metaConfidence: number;
  changelogEntries: string[];
  rawAnalysis: string;
}

export class ParadigmRunner {
  private modelClient: ModelClient;
  private idGen: IdGenerator;

  constructor(modelClient: ModelClient, idGen: IdGenerator) {
    this.modelClient = modelClient;
    this.idGen = idGen;
  }

  async run(dialogs: RawDialog[], treeData: TreeData, paradigmText: string,
    metaCurrent: string, isDeep: boolean): Promise<ParadigmResult> {
    let systemPrompt = this.buildSystemPrompt(paradigmText, isDeep);
    let userPrompt = this.buildUserPrompt(dialogs, treeData, metaCurrent);
    let resp = await this.modelClient.chatWithSystem(systemPrompt, userPrompt);

    if (!resp.success) {
      return this.emptyResult(resp.error);
    }
    return this.parseResult(resp.content, dialogs);
  }

  private buildSystemPrompt(paradigmText: string, isDeep: boolean): string {
    let mode = isDeep ? '深度进化（全盘重整）' : '普通进化（增量梳理）';
    return '你是 mywiny 思维的翅膀的思考引擎。当前模式：' + mode + '。\n' +
      '你必须严格按照以下思考范式依次执行8大核心模型：\n' + paradigmText + '\n\n' +
      '执行要求：\n' +
      '1. 模型1 事实与观点抽取：区分客观事实、主观观点、情绪感受\n' +
      '2. 模型2 显性-隐性平衡校验：锚定用户主线，保留多角度，不脑补不字面僵化\n' +
      '3. 模型3 观点冲突识别：区分事实冲突与用户观点迭代（观点迭代不计冲突）\n' +
      '4. 模型4 话题关联：匹配已有话题或新建，带 ref 溯源\n' +
      '5. 模型5 项目归类：话题归纳到项目，支持多对多\n' +
      '6. 模型6 溯源标记：所有节点必须携带 ref: Dxxx 格式溯源\n' +
      '7. 模型7 元理解汇总：迭代元理解，输出置信度\n' +
      '8. 模型8 变更与快照：记录变更日志\n\n' +
      '只回答JSON格式（不要markdown代码块）：\n' +
      '{"newTopics":[{"title":"","parentId":"ROOT","level":1,"refs":["D0001"],"description":""}],' +
      '"updatedTopics":[{"id":"T0001","title":"","refs":["D0001"],"description":""}],' +
      '"newProjects":[{"title":"","topicIds":["T0001"],"refs":["D0001"],"description":""}],' +
      '"conflicts":[{"topicId":"","severity":0,"description":"","refs":["D0001"]}],' +
      '"metaUpdate":"","metaConfidence":90,' +
      '"changelog":["变更记录1","变更记录2"]}';
  }

  private buildUserPrompt(dialogs: RawDialog[], treeData: TreeData, metaCurrent: string): string {
    let sb = '【本轮原始对话素材】\n';
    for (let i = 0; i < dialogs.length; i++) {
      sb += dialogs[i].id + ': ' + dialogs[i].content + '\n';
    }
    sb += '\n【当前话题树】\n';
    for (let i = 0; i < treeData.topics.length; i++) {
      let t = treeData.topics[i];
      if (!t.archived) {
        sb += t.id + ' | ' + t.title + ' | parent:' + t.parentId + ' | level:' + t.level +
          ' | ref:' + t.refs.join(',') + '\n';
      }
    }
    sb += '\n【当前项目树】\n';
    for (let i = 0; i < treeData.projects.length; i++) {
      let p = treeData.projects[i];
      sb += p.id + ' | ' + p.title + ' | topics:' + p.topicIds.join(',') +
        ' | ref:' + p.refs.join(',') + '\n';
    }
    sb += '\n【当前元理解】\n' + metaCurrent + '\n';
    return sb;
  }

  private parseResult(content: string, dialogs: RawDialog[]): ParadigmResult {
    let jsonStr = this.extractJson(content);
    try {
      let obj = JSON.parse(jsonStr) as ParadigmParsed;
      let allRefs = this.collectRefs(dialogs);
      let newTopics = this.parseNewTopics(obj.newTopics || [], allRefs);
      let updatedTopics = this.parseUpdatedTopics(obj.updatedTopics || [], allRefs);
      let newProjects = this.parseNewProjects(obj.newProjects || [], newTopics, allRefs);
      let conflicts = this.parseConflicts(obj.conflicts || [], allRefs);
      let metaUpdate = obj.metaUpdate !== undefined ? obj.metaUpdate : '';
      let metaConfidence = obj.metaConfidence !== undefined ? obj.metaConfidence : 90;
      let changelog = this.parseChangelog(obj.changelog || []);
      return {
        newTopics: newTopics,
        updatedTopics: updatedTopics,
        newProjects: newProjects,
        conflicts: conflicts,
        metaUpdateContent: metaUpdate,
        metaConfidence: metaConfidence,
        changelogEntries: changelog,
        rawAnalysis: content,
      };
    } catch (e) {
      return this.emptyResult('解析失败: ' + String(e));
    }
  }

  private parseNewTopics(arr: NewTopicItem[], allRefs: string[]): TopicNode[] {
    let topics: TopicNode[] = [];
    for (let i = 0; i < arr.length; i++) {
      let item = arr[i];
      let id = this.idGen.nextTopicId();
      topics.push({
        id: id,
        title: item.title || '未命名话题',
        parentId: item.parentId || 'ROOT',
        level: item.level || 1,
        refs: item.refs && item.refs.length > 0 ? item.refs : allRefs,
        activeWeight: 100,
        archived: false,
        description: item.description || '',
      });
    }
    return topics;
  }

  private parseUpdatedTopics(arr: UpdatedTopicItem[], allRefs: string[]): TopicNode[] {
    let topics: TopicNode[] = [];
    for (let i = 0; i < arr.length; i++) {
      let item = arr[i];
      topics.push({
        id: item.id || '',
        title: item.title || '',
        parentId: '',
        level: 0,
        refs: item.refs && item.refs.length > 0 ? item.refs : allRefs,
        activeWeight: 100,
        archived: false,
        description: item.description || '',
      });
    }
    return topics;
  }

  private parseNewProjects(arr: NewProjectItem[], newTopics: TopicNode[], allRefs: string[]): ProjectNode[] {
    let projects: ProjectNode[] = [];
    for (let i = 0; i < arr.length; i++) {
      let item = arr[i];
      let id = this.idGen.nextProjectId();
      projects.push({
        id: id,
        title: item.title || '未命名项目',
        topicIds: item.topicIds || [],
        refs: item.refs && item.refs.length > 0 ? item.refs : allRefs,
        description: item.description || '',
      });
    }
    return projects;
  }

  private parseConflicts(arr: ConflictItem[], allRefs: string[]): ConflictRecord[] {
    let conflicts: ConflictRecord[] = [];
    for (let i = 0; i < arr.length; i++) {
      let item = arr[i];
      conflicts.push({
        id: '',
        topicId: item.topicId || '',
        severity: item.severity || 0,
        description: item.description || '',
        solutions: [],
        chosenLabel: '',
        refs: item.refs && item.refs.length > 0 ? item.refs : allRefs,
        resolved: false,
      });
    }
    return conflicts;
  }

  private parseChangelog(arr: string[]): string[] {
    let entries: string[] = [];
    if (!arr) {
      return entries;
    }
    for (let i = 0; i < arr.length; i++) {
      entries.push(arr[i]);
    }
    return entries;
  }

  private collectRefs(dialogs: RawDialog[]): string[] {
    let refs: string[] = [];
    for (let i = 0; i < dialogs.length; i++) {
      refs.push(dialogs[i].id);
    }
    return refs;
  }

  private extractJson(content: string): string {
    let s = content.trim();
    let braceStart = s.indexOf('{');
    let braceEnd = s.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      return s.substring(braceStart, braceEnd + 1);
    }
    return '{}';
  }

  private emptyResult(error: string): ParadigmResult {
    return {
      newTopics: [],
      updatedTopics: [],
      newProjects: [],
      conflicts: [],
      metaUpdateContent: '',
      metaConfidence: 0,
      changelogEntries: [],
      rawAnalysis: '错误: ' + error,
    };
  }
}

interface NewTopicItem {
  title?: string;
  parentId?: string;
  level?: number;
  refs?: string[];
  description?: string;
}

interface UpdatedTopicItem {
  id?: string;
  title?: string;
  refs?: string[];
  description?: string;
}

interface NewProjectItem {
  title?: string;
  topicIds?: string[];
  refs?: string[];
  description?: string;
}

interface ConflictItem {
  topicId?: string;
  severity?: number;
  description?: string;
  refs?: string[];
}

interface ParadigmParsed {
  newTopics?: NewTopicItem[];
  updatedTopics?: UpdatedTopicItem[];
  newProjects?: NewProjectItem[];
  conflicts?: ConflictItem[];
  metaUpdate?: string;
  metaConfidence?: number;
  changelog?: string[];
}
