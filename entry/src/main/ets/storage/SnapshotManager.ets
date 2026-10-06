import { SnapshotMeta, SnapshotType } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';

export class SnapshotManager {
  private dirManager: DirManager;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
  }

  createSnapshot(type: SnapshotType, note: string): string {
    let id = this.nextSnapshotId(type);
    let ts = FileUtil.getTimestamp();
    let sb = '# snapshot: ' + id + '\n';
    sb += 'time: ' + FileUtil.formatTime(ts) + '\n';
    sb += 'ts: ' + ts + '\n';
    sb += 'note: ' + note + '\n';
    sb += '=== topic_tree.md ===\n';
    sb += FileUtil.readText(this.dirManager.getTopicTreePath());
    sb += '\n=== project_tree.md ===\n';
    sb += FileUtil.readText(this.dirManager.getProjectTreePath());
    sb += '\n=== meta_current.md ===\n';
    sb += FileUtil.readText(this.dirManager.getMetaCurrentPath());
    sb += '\n=== resident_layer.txt ===\n';
    sb += FileUtil.readText(this.dirManager.getResidentLayerPath());
    sb += '\n';
    FileUtil.writeText(this.dirManager.getSnapshotMainDir() + '/' + id + '.md', sb);
    return id;
  }

  listSnapshots(): SnapshotMeta[] {
    let files = FileUtil.listDir(this.dirManager.getSnapshotMainDir());
    let snapshots: SnapshotMeta[] = [];
    for (let i = 0; i < files.length; i++) {
      let name = files[i];
      if (!name.startsWith('v') || !name.endsWith('.md')) {
        continue;
      }
      let meta = this.parseSnapshotMeta(name);
      if (meta !== null) {
        snapshots.push(meta);
      }
    }
    snapshots.sort((a: SnapshotMeta, b: SnapshotMeta): number => b.timestamp - a.timestamp);
    return snapshots;
  }

  rollback(snapshotId: string): boolean {
    let path = this.dirManager.getSnapshotMainDir() + '/' + snapshotId + '.md';
    if (!FileUtil.exists(path)) {
      return false;
    }
    let text = FileUtil.readText(path);
    let sections = this.extractSections(text);
    if (sections.topicTree !== null) {
      FileUtil.writeText(this.dirManager.getTopicTreePath(), sections.topicTree);
    }
    if (sections.projectTree !== null) {
      FileUtil.writeText(this.dirManager.getProjectTreePath(), sections.projectTree);
    }
    if (sections.metaCurrent !== null) {
      FileUtil.writeText(this.dirManager.getMetaCurrentPath(), sections.metaCurrent);
    }
    if (sections.residentLayer !== null) {
      FileUtil.writeText(this.dirManager.getResidentLayerPath(), sections.residentLayer);
    }
    return true;
  }

  cleanup(retainCount: number, type: SnapshotType): void {
    let snapshots = this.listSnapshots();
    let typed: SnapshotMeta[] = [];
    for (let i = 0; i < snapshots.length; i++) {
      if (snapshots[i].type === type) {
        typed.push(snapshots[i]);
      }
    }
    for (let i = retainCount; i < typed.length; i++) {
      FileUtil.deleteFile(this.dirManager.getSnapshotMainDir() + '/' + typed[i].id + '.md');
    }
  }

  createParadigmSnapshot(note: string): string {
    let ts = FileUtil.getTimestamp();
    let id = 'vp' + ts;
    let sb = '# paradigm snapshot: ' + id + '\n';
    sb += 'time: ' + FileUtil.formatTime(ts) + '\n';
    sb += 'note: ' + note + '\n';
    sb += '=== thinking_paradigm.md ===\n';
    sb += FileUtil.readText(this.dirManager.getThinkingParadigmPath());
    sb += '\n';
    FileUtil.writeText(this.dirManager.getSnapshotParadigmDir() + '/' + id + '.md', sb);
    return id;
  }

  private nextSnapshotId(type: SnapshotType): string {
    let files = FileUtil.listDir(this.dirManager.getSnapshotMainDir());
    let maxNum = 0;
    for (let i = 0; i < files.length; i++) {
      let name = files[i];
      if (name.startsWith('v') && name.endsWith('.md')) {
        let core = name.substring(1, name.length - 3);
        let dashIdx = core.indexOf('-');
        if (dashIdx > 0) {
          let num = parseInt(core.substring(0, dashIdx), 10);
          if (!isNaN(num) && num > maxNum) {
            maxNum = num;
          }
        }
      }
    }
    let s = '' + (maxNum + 1);
    while (s.length < 3) {
      s = '0' + s;
    }
    return 'v' + s + '-' + type;
  }

  private parseSnapshotMeta(fileName: string): SnapshotMeta | null {
    let path = this.dirManager.getSnapshotMainDir() + '/' + fileName;
    let text = FileUtil.readText(path);
    let id = fileName.substring(0, fileName.length - 3);
    let type: SnapshotType = id.endsWith('-deep') ? 'deep' : 'inc';
    let ts = 0;
    let note = '';
    let lines = text.split('\n');
    for (let i = 0; i < lines.length && i < 10; i++) {
      let line = lines[i].trim();
      if (line.startsWith('ts:')) {
        ts = parseInt(line.substring(3).trim(), 10) || 0;
      } else if (line.startsWith('note:')) {
        note = line.substring(5).trim();
      }
    }
    return { id: id, type: type, timestamp: ts, note: note };
  }

  private extractSections(text: string): SnapshotSections {
    return {
      topicTree: this.extractSection(text, 'topic_tree.md'),
      projectTree: this.extractSection(text, 'project_tree.md'),
      metaCurrent: this.extractSection(text, 'meta_current.md'),
      residentLayer: this.extractSection(text, 'resident_layer.txt'),
    };
  }

  private extractSection(text: string, name: string): string | null {
    let marker = '=== ' + name + ' ===\n';
    let start = text.indexOf(marker);
    if (start < 0) {
      return null;
    }
    let contentStart = start + marker.length;
    let endMarker = '\n=== ';
    let end = text.indexOf(endMarker, contentStart);
    if (end < 0) {
      end = text.length;
    }
    return text.substring(contentStart, end).trim();
  }
}

interface SnapshotSections {
  topicTree: string | null;
  projectTree: string | null;
  metaCurrent: string | null;
  residentLayer: string | null;
}
