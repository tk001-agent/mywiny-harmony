import { MetaInfo } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';

export class MetaStorage {
  private dirManager: DirManager;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
  }

  readMetaBase(): string {
    return FileUtil.readText(this.dirManager.getMetaBasePath());
  }

  writeMetaBase(content: string): void {
    FileUtil.writeText(this.dirManager.getMetaBasePath(), content);
  }

  readMetaCurrent(): MetaInfo {
    let text = FileUtil.readText(this.dirManager.getMetaCurrentPath());
    return this.parseMetaCurrent(text);
  }

  writeMetaCurrent(meta: MetaInfo): void {
    let text = '# meta_current.md · 运行时元理解\n' +
      '版本：' + meta.version + '\n' +
      '置信度：' + meta.confidence + '\n' +
      '时间：' + FileUtil.formatTime(meta.timestamp) + '\n' +
      '待复核：' + meta.needReview + '\n' +
      '\n' +
      meta.content + '\n';
    FileUtil.writeText(this.dirManager.getMetaCurrentPath(), text);
  }

  appendMetaChangelog(entry: string): void {
    FileUtil.appendText(this.dirManager.getMetaChangelogPath(),
      '\n[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  readMetaChangelog(): string {
    return FileUtil.readText(this.dirManager.getMetaChangelogPath());
  }

  private parseMetaCurrent(text: string): MetaInfo {
    let version = 1;
    let confidence = 100;
    let timestamp = 0;
    let needReview = false;
    let lines = text.split('\n');
    let contentStart = 0;
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (line.startsWith('版本：')) {
        version = parseInt(line.substring(3).trim(), 10) || 1;
      } else if (line.startsWith('置信度：')) {
        confidence = parseInt(line.substring(4).trim(), 10) || 100;
      } else if (line.startsWith('时间：')) {
        timestamp = Date.parse(line.substring(3).trim()) || 0;
      } else if (line.startsWith('待复核：')) {
        needReview = line.substring(4).trim() === 'true';
      } else if (line.length === 0 && i > 0 && contentStart === 0) {
        contentStart = i + 1;
      }
    }
    let content = '';
    if (contentStart > 0 && contentStart < lines.length) {
      content = lines.slice(contentStart).join('\n').trim();
    }
    return {
      version: version, content: content, confidence: confidence,
      timestamp: timestamp, needReview: needReview,
    };
  }

  readResidentLayer(): string {
    return FileUtil.readText(this.dirManager.getResidentLayerPath());
  }

  writeResidentLayer(content: string): void {
    FileUtil.writeText(this.dirManager.getResidentLayerPath(), content);
  }

  appendAutorunlog(entry: string): void {
    FileUtil.appendText(this.dirManager.getAutorunlogPath(),
      '[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  readAutorunlog(): string {
    return FileUtil.readText(this.dirManager.getAutorunlogPath());
  }

  readLastEvolutionTime(): number {
    let text = FileUtil.readText(this.dirManager.getLastEvolutionPath());
    return parseInt(text.trim(), 10) || 0;
  }

  writeLastEvolutionTime(ts: number): void {
    FileUtil.writeText(this.dirManager.getLastEvolutionPath(), '' + ts);
  }
}
