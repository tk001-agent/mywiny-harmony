import { AppConfig, DEFAULT_CONFIG } from '../model/DataTypes';
import { FileUtil } from './FileUtil';
import { DirManager } from './DirManager';

export class ConfigManager {
  private dirManager: DirManager;
  private config: AppConfig;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
    this.config = DEFAULT_CONFIG;
    this.load();
  }

  load(): void {
    let path = this.dirManager.getConfigPath();
    if (!FileUtil.exists(path)) {
      this.config = DEFAULT_CONFIG;
      this.save();
      return;
    }
    let text = FileUtil.readText(path);
    this.config = this.parseIni(text);
  }

  save(): void {
    let text = this.buildIni(this.config);
    FileUtil.writeText(this.dirManager.getConfigPath(), text);
  }

  getConfig(): AppConfig {
    return this.config;
  }

  updateConfig(config: AppConfig): void {
    this.config = config;
    this.save();
  }

  private parseIni(text: string): AppConfig {
    let cfg: AppConfig = {
      incRetainCount: DEFAULT_CONFIG.incRetainCount,
      deepRetainCount: DEFAULT_CONFIG.deepRetainCount,
      paradigmRetainCount: DEFAULT_CONFIG.paradigmRetainCount,
      residentLayerMaxChars: DEFAULT_CONFIG.residentLayerMaxChars,
      conflictThreshold: DEFAULT_CONFIG.conflictThreshold,
      paradigmSubmoduleMax: DEFAULT_CONFIG.paradigmSubmoduleMax,
      modelMode: DEFAULT_CONFIG.modelMode,
      warnTimeCost: DEFAULT_CONFIG.warnTimeCost,
    };
    let lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (line.length === 0 || line.startsWith('[') || line.startsWith(';') || line.startsWith('#')) {
        continue;
      }
      let eqIdx = line.indexOf('=');
      if (eqIdx < 0) {
        continue;
      }
      let key = line.substring(0, eqIdx).trim();
      let val = line.substring(eqIdx + 1).trim();
      let semiIdx = val.indexOf(';');
      if (semiIdx >= 0) {
        val = val.substring(0, semiIdx).trim();
      }
      this.applyValue(cfg, key, val);
    }
    return cfg;
  }

  private applyValue(cfg: AppConfig, key: string, val: string): void {
    switch (key) {
      case 'inc_retain_count':
        cfg.incRetainCount = parseInt(val, 10) || cfg.incRetainCount;
        break;
      case 'deep_retain_count':
        cfg.deepRetainCount = parseInt(val, 10) || cfg.deepRetainCount;
        break;
      case 'paradigm_retain_count':
        cfg.paradigmRetainCount = parseInt(val, 10) || cfg.paradigmRetainCount;
        break;
      case 'resident_layer_max_chars':
        cfg.residentLayerMaxChars = parseInt(val, 10) || cfg.residentLayerMaxChars;
        break;
      case 'conflict_threshold':
        cfg.conflictThreshold = parseInt(val, 10) || cfg.conflictThreshold;
        break;
      case 'paradigm_submodule_max':
        cfg.paradigmSubmoduleMax = parseInt(val, 10) || cfg.paradigmSubmoduleMax;
        break;
      case 'model_mode':
        cfg.modelMode = val;
        break;
      case 'warn_time_cost':
        cfg.warnTimeCost = parseInt(val, 10) || cfg.warnTimeCost;
        break;
      default:
        break;
    }
  }

  private buildIni(cfg: AppConfig): string {
    return '[snapshot]\n' +
      'inc_retain_count=' + cfg.incRetainCount + '\n' +
      'deep_retain_count=' + cfg.deepRetainCount + '\n' +
      'paradigm_retain_count=' + cfg.paradigmRetainCount + '\n' +
      '[evolution]\n' +
      'resident_layer_max_chars=' + cfg.residentLayerMaxChars + '\n' +
      'conflict_threshold=' + cfg.conflictThreshold + '\n' +
      'paradigm_submodule_max=' + cfg.paradigmSubmoduleMax + '\n' +
      '[model]\n' +
      'model_mode=' + cfg.modelMode + '\n' +
      'warn_time_cost=' + cfg.warnTimeCost + '\n';
  }
}
