import { ParadigmSubModule, SubModuleStatus } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';

interface ParseResult {
  module: ParadigmSubModule;
  endIndex: number;
}

export class ParadigmStorage {
  private dirManager: DirManager;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
  }

  readParadigm(): string {
    return FileUtil.readText(this.dirManager.getThinkingParadigmPath());
  }

  writeParadigm(content: string): void {
    FileUtil.writeText(this.dirManager.getThinkingParadigmPath(), content);
  }

  readExtendSubModules(): ParadigmSubModule[] {
    let text = this.readParadigm();
    let extendIdx = text.indexOf('## Paradigm-Extend');
    if (extendIdx < 0) {
      return [];
    }
    let extendText = text.substring(extendIdx);
    let lines = extendText.split('\n');
    let modules: ParadigmSubModule[] = [];
    let i = 0;
    while (i < lines.length) {
      let line = lines[i].trim();
      if (line.startsWith('# 子模块名称：')) {
        let result = this.parseSubModule(lines, i);
        if (result !== null) {
          modules.push(result.module);
          i = result.endIndex;
          continue;
        }
      }
      i++;
    }
    return modules;
  }

  writeExtendSubModules(modules: ParadigmSubModule[]): void {
    let text = this.readParadigm();
    let baseEnd = text.indexOf('## Paradigm-Extend');
    if (baseEnd < 0) {
      baseEnd = text.length;
    }
    let basePart = text.substring(0, baseEnd);
    let sb = basePart + '## Paradigm-Extend 范式扩展层\n';
    if (modules.length === 0) {
      sb += '（初始为空，随深度进化复盘沉淀子思考模块）\n';
    } else {
      for (let i = 0; i < modules.length; i++) {
        sb += this.formatSubModule(modules[i]) + '\n';
      }
    }
    this.writeParadigm(sb);
  }

  appendParadigmChangelog(entry: string): void {
    FileUtil.appendText(this.dirManager.getParadigmChangelogPath(),
      '\n[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  readParadigmChangelog(): string {
    return FileUtil.readText(this.dirManager.getParadigmChangelogPath());
  }

  private parseSubModule(lines: string[], start: number): ParseResult | null {
    let name = lines[start].trim().substring('# 子模块名称：'.length).trim();
    let scene = '';
    let coreModel = '';
    let effect = '';
    let refs: string[] = [];
    let activity = 100;
    let status: SubModuleStatus = 'active';
    let dimensions: string[] = [];
    let inDimensions = false;
    let end = start + 1;
    for (let i = start + 1; i < lines.length; i++) {
      let line = lines[i].trim();
      if (line.startsWith('# 子模块名称：')) {
        end = i;
        break;
      }
      if (line.startsWith('适用场景：')) {
        scene = line.substring('适用场景：'.length).trim();
        inDimensions = false;
      } else if (line.startsWith('所属核心模型：')) {
        coreModel = line.substring('所属核心模型：'.length).trim();
        inDimensions = false;
      } else if (line.startsWith('分析维度：')) {
        inDimensions = true;
      } else if (line.startsWith('效果预期：')) {
        effect = line.substring('效果预期：'.length).trim();
        inDimensions = false;
      } else if (line.startsWith('溯源ref：')) {
        let r = line.substring('溯源ref：'.length).trim();
        refs = r.length > 0 ? r.split(',') : [];
        inDimensions = false;
      } else if (line.startsWith('活跃度：')) {
        let a = line.substring('活跃度：'.length).trim();
        activity = parseInt(a, 10) || 100;
        inDimensions = false;
      } else if (line.startsWith('状态：')) {
        let s = line.substring('状态：'.length).trim();
        status = s.includes('休眠') ? 'dormant' : 'active';
        inDimensions = false;
        end = i + 1;
      } else if (inDimensions && line.startsWith('- ')) {
        dimensions.push(line.substring(2).trim());
      }
      if (i === lines.length - 1) {
        end = lines.length;
      }
    }
    let module: ParadigmSubModule = {
      name: name, scene: scene, coreModel: coreModel, dimensions: dimensions,
      effect: effect, refs: refs, activity: activity, status: status,
    };
    return { module: module, endIndex: end };
  }

  private formatSubModule(m: ParadigmSubModule): string {
    let sb = '# 子模块名称：' + m.name + '\n';
    sb += '适用场景：' + m.scene + '\n';
    sb += '所属核心模型：' + m.coreModel + '\n';
    sb += '分析维度：\n';
    for (let i = 0; i < m.dimensions.length; i++) {
      sb += '- ' + m.dimensions[i] + '\n';
    }
    sb += '效果预期：' + m.effect + '\n';
    sb += '溯源ref：' + m.refs.join(',') + '\n';
    sb += '活跃度：' + m.activity + '\n';
    sb += '状态：' + (m.status === 'active' ? '生效' : '休眠') + '\n';
    return sb;
  }
}
