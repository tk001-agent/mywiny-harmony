import { TopicNode, ProjectNode, TreeData } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';

export class TreeStorage {
  private dirManager: DirManager;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
  }

  readTopicTree(): TopicNode[] {
    let text = FileUtil.readText(this.dirManager.getTopicTreePath());
    let lines = text.split('\n');
    let topics: TopicNode[] = [];
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (!line.startsWith('- ')) {
        continue;
      }
      let node = this.parseTopicLine(line.substring(2));
      if (node !== null) {
        topics.push(node);
      }
    }
    return topics;
  }

  writeTopicTree(topics: TopicNode[]): void {
    let sb = '# topic_tree.md · 话题树\n';
    for (let i = 0; i < topics.length; i++) {
      sb += this.formatTopicLine(topics[i]) + '\n';
    }
    FileUtil.writeText(this.dirManager.getTopicTreePath(), sb);
  }

  readProjectTree(): ProjectNode[] {
    let text = FileUtil.readText(this.dirManager.getProjectTreePath());
    let lines = text.split('\n');
    let projects: ProjectNode[] = [];
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (!line.startsWith('- ')) {
        continue;
      }
      let node = this.parseProjectLine(line.substring(2));
      if (node !== null) {
        projects.push(node);
      }
    }
    return projects;
  }

  writeProjectTree(projects: ProjectNode[]): void {
    let sb = '# project_tree.md · 项目树\n';
    for (let i = 0; i < projects.length; i++) {
      sb += this.formatProjectLine(projects[i]) + '\n';
    }
    FileUtil.writeText(this.dirManager.getProjectTreePath(), sb);
  }

  readTreeData(): TreeData {
    return {
      topics: this.readTopicTree(),
      projects: this.readProjectTree(),
    };
  }

  appendTopicChangelog(entry: string): void {
    FileUtil.appendText(this.dirManager.getTopicChangelogPath(),
      '\n[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  appendProjectChangelog(entry: string): void {
    FileUtil.appendText(this.dirManager.getProjectChangelogPath(),
      '\n[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  private parseTopicLine(s: string): TopicNode | null {
    let parts = s.split(' | ');
    if (parts.length < 7) {
      return null;
    }
    let id = parts[0].trim();
    let title = parts[1].trim();
    let parentId = this.extractField(parts[2], 'parent:');
    let level = parseInt(this.extractField(parts[3], 'level:'), 10) || 1;
    let refs = this.extractRefs(parts[4]);
    let weight = parseInt(this.extractField(parts[5], 'weight:'), 10) || 100;
    let archived = this.extractField(parts[6], 'archived:') === 'true';
    let description = '';
    if (parts.length > 7) {
      description = this.extractField(parts[7], 'desc:');
    }
    return {
      id: id, title: title, parentId: parentId, level: level,
      refs: refs, activeWeight: weight, archived: archived, description: description,
    };
  }

  private formatTopicLine(t: TopicNode): string {
    return '- ' + t.id + ' | ' + t.title + ' | parent:' + t.parentId +
      ' | level:' + t.level + ' | ref:' + t.refs.join(',') +
      ' | weight:' + t.activeWeight + ' | archived:' + t.archived +
      ' | desc:' + t.description;
  }

  private parseProjectLine(s: string): ProjectNode | null {
    let parts = s.split(' | ');
    if (parts.length < 4) {
      return null;
    }
    let id = parts[0].trim();
    let title = parts[1].trim();
    let topicIds = this.extractField(parts[2], 'topics:').split(',');
    if (topicIds.length === 1 && topicIds[0] === '') {
      topicIds = [];
    }
    let refs = this.extractRefs(parts[3]);
    let description = '';
    if (parts.length > 4) {
      description = this.extractField(parts[4], 'desc:');
    }
    return { id: id, title: title, topicIds: topicIds, refs: refs, description: description };
  }

  private formatProjectLine(p: ProjectNode): string {
    return '- ' + p.id + ' | ' + p.title + ' | topics:' + p.topicIds.join(',') +
      ' | ref:' + p.refs.join(',') + ' | desc:' + p.description;
  }

  private extractField(s: string, prefix: string): string {
    let idx = s.indexOf(prefix);
    if (idx < 0) {
      return '';
    }
    return s.substring(idx + prefix.length).trim();
  }

  private extractRefs(s: string): string[] {
    let val = this.extractField(s, 'ref:');
    if (val.length === 0) {
      return [];
    }
    return val.split(',');
  }

  appendConflictArchive(entry: string): void {
    FileUtil.appendText(this.dirManager.getConflictArchivePath(),
      '\n[' + FileUtil.formatTime(FileUtil.getTimestamp()) + '] ' + entry + '\n');
  }

  readConflictArchive(): string {
    return FileUtil.readText(this.dirManager.getConflictArchivePath());
  }
}
