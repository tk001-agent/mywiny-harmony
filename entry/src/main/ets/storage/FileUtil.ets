import fs from '@ohos.file.fs';
import { util } from '@kit.ArkTS';

export class FileUtil {
  static exists(path: string): boolean {
    try {
      fs.accessSync(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  static mkdirs(path: string): void {
    if (FileUtil.exists(path)) {
      return;
    }
    fs.mkdirSync(path, true);
  }

  static readText(path: string): string {
    if (!FileUtil.exists(path)) {
      return '';
    }
    let file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    try {
      let stat = fs.statSync(path);
      if (stat.size === 0) {
        return '';
      }
      let buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      let decoder = util.TextDecoder.create('utf-8');
      return decoder.decodeWithStream(buf);
    } finally {
      fs.closeSync(file);
    }
  }

  static writeText(path: string, content: string): void {
    let file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, content);
    } finally {
      fs.closeSync(file);
    }
  }

  static appendText(path: string, content: string): void {
    let file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.APPEND);
    try {
      fs.writeSync(file.fd, content);
    } finally {
      fs.closeSync(file);
    }
  }

  static deleteFile(path: string): void {
    if (FileUtil.exists(path)) {
      fs.unlinkSync(path);
    }
  }

  static listDir(path: string): string[] {
    if (!FileUtil.exists(path)) {
      return [];
    }
    let result: string[] = [];
    let entries = fs.listFileSync(path);
    for (let i = 0; i < entries.length; i++) {
      result.push(entries[i]);
    }
    return result;
  }

  static copyFile(srcPath: string, dstPath: string): void {
    if (!FileUtil.exists(srcPath)) {
      return;
    }
    let content = FileUtil.readText(srcPath);
    FileUtil.writeText(dstPath, content);
  }

  static getTimestamp(): number {
    return Date.now();
  }

  static formatTime(ts: number): string {
    let d = new Date(ts);
    let pad = (n: number): string => n < 10 ? '0' + n : '' + n;
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
      ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
  }
}
