import { DirManager } from '../storage/DirManager';
import { IdGenerator } from '../storage/IdGenerator';
import { ConfigManager } from '../storage/ConfigManager';
import { RawStorage } from '../storage/RawStorage';
import { TreeStorage } from '../storage/TreeStorage';
import { MetaStorage } from '../storage/MetaStorage';
import { ParadigmStorage } from '../storage/ParadigmStorage';
import { SnapshotManager } from '../storage/SnapshotManager';
import { BackupManager } from '../storage/BackupManager';
import { ModelClient } from '../engine/ModelClient';
import { EvolutionEngine } from '../engine/EvolutionEngine';

export class AppContext {
  private static instance: AppContext | null = null;

  dirManager: DirManager;
  idGen: IdGenerator;
  configManager: ConfigManager;
  rawStorage: RawStorage;
  treeStorage: TreeStorage;
  metaStorage: MetaStorage;
  paradigmStorage: ParadigmStorage;
  snapshotManager: SnapshotManager;
  backupManager: BackupManager;
  modelClient: ModelClient;
  evolutionEngine: EvolutionEngine;

  private constructor(filesDir: string) {
    this.dirManager = new DirManager(filesDir);
    this.dirManager.initAll();
    this.idGen = new IdGenerator(this.dirManager);
    this.configManager = new ConfigManager(this.dirManager);
    this.rawStorage = new RawStorage(this.dirManager, this.idGen);
    this.treeStorage = new TreeStorage(this.dirManager);
    this.metaStorage = new MetaStorage(this.dirManager);
    this.paradigmStorage = new ParadigmStorage(this.dirManager);
    this.snapshotManager = new SnapshotManager(this.dirManager);
    this.backupManager = new BackupManager(this.dirManager);
    this.modelClient = new ModelClient(this.dirManager);
    this.evolutionEngine = new EvolutionEngine(
      this.rawStorage, this.treeStorage, this.metaStorage,
      this.paradigmStorage, this.snapshotManager, this.idGen,
      this.configManager, this.modelClient);
  }

  static init(filesDir: string): void {
    if (AppContext.instance === null) {
      AppContext.instance = new AppContext(filesDir);
    }
  }

  static getInstance(): AppContext {
    if (AppContext.instance === null) {
      throw new Error('AppContext not initialized');
    }
    return AppContext.instance;
  }
}
