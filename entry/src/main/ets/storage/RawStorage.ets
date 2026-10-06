import { RawDialog } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';
import { IdGenerator } from './IdGenerator';

export class RawStorage {
  private dirManager: DirManager;
  private idGen: IdGenerator;

  constructor(dirManager: DirManager, idGen: IdGenerator) {
    this.dirManager = dirManager;
    this.idGen = idGen;
  }

  appendDialog(content: string): string {
    let id = this.idGen.nextDialogId();
    let ts = FileUtil.getTimestamp();
    let text = '# ' + id + '\n' +
      'time: ' + FileUtil.formatTime(ts) + '\n' +
      'ts: ' + ts + '\n' +
      '\n' +
      content + '\n';
    FileUtil.writeText(this.dirManager.getRawDialogPath(id), text);
    return id;
  }

  getDialog(id: string): RawDialog | null {
    let path = this.dirManager.getRawDialogPath(id);
    if (!FileUtil.exists(path)) {
      return null;
    }
    let text = FileUtil.readText(path);
    return this.parseDialog(id, text);
  }

  private parseDialog(id: string, text: string): RawDialog {
    let ts = 0;
    let lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (line.startsWith('ts:')) {
        ts = parseInt(line.substring(3).trim(), 10) || 0;
        break;
      }
    }
    let content = text;
    let firstNl = text.indexOf('\n');
    if (firstNl >= 0) {
      let rest = text.substring(firstNl + 1);
      let contentStart = rest.indexOf('\n\n');
      if (contentStart >= 0) {
        content = rest.substring(contentStart + 2).trim();
      }
    }
    return { id: id, content: content, timestamp: ts };
  }

  listDialogs(): RawDialog[] {
    let files = FileUtil.listDir(this.dirManager.getRawDir());
    let dialogs: RawDialog[] = [];
    for (let i = 0; i < files.length; i++) {
      let name = files[i];
      if (name.startsWith('D') && name.endsWith('.md')) {
        let id = name.substring(0, name.length - 3);
        let d = this.getDialog(id);
        if (d !== null) {
          dialogs.push(d);
        }
      }
    }
    dialogs.sort((a: RawDialog, b: RawDialog): number => b.timestamp - a.timestamp);
    return dialogs;
  }

  searchDialogs(keyword: string): RawDialog[] {
    let all = this.listDialogs();
    let kw = keyword.toLowerCase();
    let result: RawDialog[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].content.toLowerCase().includes(kw) || all[i].id.toLowerCase().includes(kw)) {
        result.push(all[i]);
      }
    }
    return result;
  }

  getLastDialogTime(): number {
    let dialogs = this.listDialogs();
    if (dialogs.length === 0) {
      return 0;
    }
    return dialogs[0].timestamp;
  }

  getCount(): number {
    let files = FileUtil.listDir(this.dirManager.getRawDir());
    let count = 0;
    for (let i = 0; i < files.length; i++) {
      if (files[i].startsWith('D') && files[i].endsWith('.md')) {
        count++;
      }
    }
    return count;
  }
}
