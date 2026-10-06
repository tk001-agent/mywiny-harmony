import { Constants } from '../common/Constants';
import { FileUtil } from './FileUtil';

export class DirManager {
  private baseDir: string;
  private appDir: string;

  constructor(filesDir: string) {
    this.baseDir = filesDir;
    this.appDir = filesDir + '/' + Constants.APP_DIR;
  }

  initAll(): void {
    FileUtil.mkdirs(this.appDir);
    FileUtil.mkdirs(this.getRawDir());
    FileUtil.mkdirs(this.getInferDir());
    FileUtil.mkdirs(this.getArchiveDir());
    FileUtil.mkdirs(this.getEvolutionDir());
    FileUtil.mkdirs(this.getMetaDir());
    FileUtil.mkdirs(this.getSnapshotDir());
    FileUtil.mkdirs(this.getSnapshotMainDir());
    FileUtil.mkdirs(this.getSnapshotParadigmDir());
    this.initFiles();
  }

  private initFiles(): void {
    this.ensureFile(this.getMetaBasePath(), Constants.META_BASE_INIT_CONTENT);
    this.ensureFile(this.getMetaCurrentPath(), Constants.META_CURRENT_INIT_CONTENT);
    this.ensureFile(this.getMetaChangelogPath(), Constants.META_CHANGELOG_INIT_CONTENT);
    this.ensureFile(this.getTopicTreePath(), Constants.TOPIC_TREE_INIT_CONTENT);
    this.ensureFile(this.getTopicChangelogPath(), Constants.TOPIC_CHANGELOG_INIT_CONTENT);
    this.ensureFile(this.getProjectTreePath(), Constants.PROJECT_TREE_INIT_CONTENT);
    this.ensureFile(this.getProjectChangelogPath(), Constants.PROJECT_CHANGELOG_INIT_CONTENT);
    this.ensureFile(this.getResidentLayerPath(), Constants.RESIDENT_LAYER_INIT_CONTENT);
    this.ensureFile(this.getAutorunlogPath(), Constants.AUTORUNLOG_INIT_CONTENT);
    this.ensureFile(this.getConflictArchivePath(), Constants.CONFLICT_ARCHIVE_INIT_CONTENT);
    this.ensureFile(this.getThinkingParadigmPath(), Constants.THINKING_PARADIGM_INIT_CONTENT);
    this.ensureFile(this.getParadigmChangelogPath(), Constants.PARADIGM_CHANGELOG_INIT_CONTENT);
    this.ensureFile(this.getLastEvolutionPath(), Constants.LAST_EVOLUTION_INIT);
    this.ensureFile(this.getReadmePath(), Constants.README_INIT_CONTENT);
  }

  private ensureFile(path: string, initContent: string): void {
    if (!FileUtil.exists(path)) {
      FileUtil.writeText(path, initContent);
    }
  }

  getAppDir(): string { return this.appDir; }
  getRawDir(): string { return this.appDir + '/' + Constants.RAW_DIR; }
  getEvolutionDir(): string { return this.appDir + '/' + Constants.EVOLUTION_DIR; }
  getMetaDir(): string { return this.getEvolutionDir() + '/' + Constants.META_DIR; }
  getSnapshotDir(): string { return this.appDir + '/' + Constants.SNAPSHOT_DIR; }
  getSnapshotMainDir(): string { return this.getSnapshotDir() + '/' + Constants.SNAPSHOT_MAIN_DIR; }
  getSnapshotParadigmDir(): string { return this.getSnapshotDir() + '/' + Constants.SNAPSHOT_PARADIGM_DIR; }
  getInferDir(): string { return this.appDir + '/' + Constants.INFER_DIR; }
  getArchiveDir(): string { return this.appDir + '/' + Constants.ARCHIVE_DIR; }

  getMetaBasePath(): string { return this.getMetaDir() + '/' + Constants.META_BASE_FILE; }
  getMetaCurrentPath(): string { return this.getMetaDir() + '/' + Constants.META_CURRENT_FILE; }
  getMetaChangelogPath(): string { return this.getMetaDir() + '/' + Constants.META_CHANGELOG_FILE; }
  getTopicTreePath(): string { return this.getEvolutionDir() + '/' + Constants.TOPIC_TREE_FILE; }
  getTopicChangelogPath(): string { return this.getEvolutionDir() + '/' + Constants.TOPIC_CHANGELOG_FILE; }
  getProjectTreePath(): string { return this.getEvolutionDir() + '/' + Constants.PROJECT_TREE_FILE; }
  getProjectChangelogPath(): string { return this.getEvolutionDir() + '/' + Constants.PROJECT_CHANGELOG_FILE; }
  getResidentLayerPath(): string { return this.getEvolutionDir() + '/' + Constants.RESIDENT_LAYER_FILE; }
  getAutorunlogPath(): string { return this.getEvolutionDir() + '/' + Constants.AUTORUNLOG_FILE; }
  getConflictArchivePath(): string { return this.getEvolutionDir() + '/' + Constants.CONFLICT_ARCHIVE_FILE; }
  getThinkingParadigmPath(): string { return this.getEvolutionDir() + '/' + Constants.THINKING_PARADIGM_FILE; }
  getParadigmChangelogPath(): string { return this.getEvolutionDir() + '/' + Constants.PARADIGM_CHANGELOG_FILE; }
  getConfigPath(): string { return this.appDir + '/' + Constants.CONFIG_FILE; }
  getLastEvolutionPath(): string { return this.appDir + '/' + Constants.LAST_EVOLUTION_FILE; }
  getReadmePath(): string { return this.appDir + '/' + Constants.README_FILE; }
  getRawDialogPath(dialogId: string): string { return this.getRawDir() + '/' + dialogId + '.md'; }
}
