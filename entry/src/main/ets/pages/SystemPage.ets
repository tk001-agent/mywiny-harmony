import { router } from '@kit.ArkUI';
import { AppContext } from '../common/AppContext';
import { ModelApiConfig } from '../engine/ModelClient';
import { AppConfig } from '../model/DataTypes';

@Entry
@Component
struct SystemPage {
  @State currentTab: number = 0;
  @State metaBaseText: string = '';
  @State metaCurrentText: string = '';
  @State autorunlogText: string = '';
  @State apiConfig: ModelApiConfig = { apiUrl: '', apiKey: '', modelName: '' };
  @State config: AppConfig = {
    incRetainCount: 5, deepRetainCount: 5, paradigmRetainCount: 5,
    residentLayerMaxChars: 2000, conflictThreshold: 5,
    paradigmSubmoduleMax: 30, modelMode: 'api', warnTimeCost: 300,
  };
  @State backupFiles: string[] = [];
  @State toastMsg: string = '';
  private appCtx: AppContext = AppContext.getInstance();
  private tabs: string[] = ['底层铁律', '元理解', '模型配置', '备份导出', '运行日志'];

  aboutToAppear(): void {
    this.refreshAll();
  }

  refreshAll(): void {
    this.metaBaseText = this.appCtx.metaStorage.readMetaBase();
    let meta = this.appCtx.metaStorage.readMetaCurrent();
    this.metaCurrentText = '版本：' + meta.version + '\n置信度：' + meta.confidence +
      '\n待复核：' + meta.needReview + '\n\n' + meta.content;
    this.autorunlogText = this.appCtx.metaStorage.readAutorunlog();
    this.apiConfig = this.appCtx.modelClient.getConfig();
    this.config = this.appCtx.configManager.getConfig();
    this.backupFiles = this.appCtx.backupManager.listBackups();
  }

  saveApiConfig(): void {
    this.appCtx.modelClient.saveConfig(this.apiConfig);
    this.showToast('模型配置已保存');
  }

  saveAppConfig(): void {
    this.appCtx.configManager.updateConfig(this.config);
    this.showToast('参数配置已保存');
  }

  doExport(): void {
    try {
      let path = this.appCtx.backupManager.exportBackup();
      this.backupFiles = this.appCtx.backupManager.listBackups();
      this.showToast('备份已导出');
    } catch (e) {
      this.showToast('导出失败: ' + String(e));
    }
  }

  showToast(msg: string): void {
    this.toastMsg = msg;
    setTimeout(() => { this.toastMsg = ''; }, 2000);
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => { router.back(); })
        Text('系统设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(13)
              .fontColor(this.currentTab === index ? '#FFFFFF' : '#333')
              .backgroundColor(this.currentTab === index ? '#007DFF' : '#EEE')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ right: 6 })
              .onClick(() => { this.currentTab = index; })
          }, (tab: string) => tab)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('92%')
      .margin({ bottom: 12 })

      if (this.currentTab === 0) {
        this.MetaBaseView()
      } else if (this.currentTab === 1) {
        this.MetaCurrentView()
      } else if (this.currentTab === 2) {
        this.ModelConfigView()
      } else if (this.currentTab === 3) {
        this.BackupView()
      } else {
        this.LogView()
      }

      if (this.toastMsg.length > 0) {
        Text(this.toastMsg)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#333')
          .padding(8)
          .borderRadius(4)
          .position({ x: '50%', y: '90%' })
      }
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  MetaBaseView() {
    Scroll() {
      Text(this.metaBaseText)
        .fontSize(13)
        .fontColor('#333')
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
    }
    .width('92%')
    .layoutWeight(1)
    .padding({ bottom: 12 })
  }

  @Builder
  MetaCurrentView() {
    Scroll() {
      Text(this.metaCurrentText)
        .fontSize(13)
        .fontColor('#333')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
    }
    .width('92%')
    .layoutWeight(1)
    .padding({ bottom: 12 })
  }

  @Builder
  ModelConfigView() {
    Scroll() {
      Column() {
        Text('大模型 API 配置')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Text('API 地址（OpenAI 兼容格式）')
          .fontSize(12)
          .fontColor('#666')
        TextInput({ placeholder: 'https://api.openai.com/v1/chat/completions', text: this.apiConfig.apiUrl })
          .width('100%')
          .fontSize(13)
          .margin({ bottom: 8 })
          .onChange((v: string) => {
            this.apiConfig = { apiUrl: v, apiKey: this.apiConfig.apiKey, modelName: this.apiConfig.modelName };
          })

        Text('API 密钥')
          .fontSize(12)
          .fontColor('#666')
        TextInput({ placeholder: 'sk-...', text: this.apiConfig.apiKey })
          .width('100%')
          .fontSize(13)
          .margin({ bottom: 8 })
          .onChange((v: string) => {
            this.apiConfig = { apiUrl: this.apiConfig.apiUrl, apiKey: v, modelName: this.apiConfig.modelName };
          })

        Text('模型名称')
          .fontSize(12)
          .fontColor('#666')
        TextInput({ placeholder: 'gpt-4o-mini', text: this.apiConfig.modelName })
          .width('100%')
          .fontSize(13)
          .margin({ bottom: 12 })
          .onChange((v: string) => {
            this.apiConfig = { apiUrl: this.apiConfig.apiUrl, apiKey: this.apiConfig.apiKey, modelName: v };
          })

        Button('保存模型配置')
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .width('100%')
          .height(40)
          .margin({ bottom: 20 })
          .onClick(() => { this.saveApiConfig(); })

        Text('进化参数配置')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Row() {
          Text('普通进化快照保留')
            .fontSize(13).fontColor('#333').layoutWeight(1)
          TextInput({ text: '' + this.config.incRetainCount })
            .width(80).fontSize(13)
            .onChange((v: string) => {
              this.config = {
                incRetainCount: parseInt(v, 10) || 5,
                deepRetainCount: this.config.deepRetainCount,
                paradigmRetainCount: this.config.paradigmRetainCount,
                residentLayerMaxChars: this.config.residentLayerMaxChars,
                conflictThreshold: this.config.conflictThreshold,
                paradigmSubmoduleMax: this.config.paradigmSubmoduleMax,
                modelMode: this.config.modelMode,
                warnTimeCost: this.config.warnTimeCost,
              };
            })
        }.width('100%').margin({ bottom: 8 })

        Row() {
          Text('深度进化快照保留')
            .fontSize(13).fontColor('#333').layoutWeight(1)
          TextInput({ text: '' + this.config.deepRetainCount })
            .width(80).fontSize(13)
            .onChange((v: string) => {
              this.config = {
                incRetainCount: this.config.incRetainCount,
                deepRetainCount: parseInt(v, 10) || 5,
                paradigmRetainCount: this.config.paradigmRetainCount,
                residentLayerMaxChars: this.config.residentLayerMaxChars,
                conflictThreshold: this.config.conflictThreshold,
                paradigmSubmoduleMax: this.config.paradigmSubmoduleMax,
                modelMode: this.config.modelMode,
                warnTimeCost: this.config.warnTimeCost,
              };
            })
        }.width('100%').margin({ bottom: 8 })

        Row() {
          Text('常驻层字符上限')
            .fontSize(13).fontColor('#333').layoutWeight(1)
          TextInput({ text: '' + this.config.residentLayerMaxChars })
            .width(80).fontSize(13)
            .onChange((v: string) => {
              this.config = {
                incRetainCount: this.config.incRetainCount,
                deepRetainCount: this.config.deepRetainCount,
                paradigmRetainCount: this.config.paradigmRetainCount,
                residentLayerMaxChars: parseInt(v, 10) || 2000,
                conflictThreshold: this.config.conflictThreshold,
                paradigmSubmoduleMax: this.config.paradigmSubmoduleMax,
                modelMode: this.config.modelMode,
                warnTimeCost: this.config.warnTimeCost,
              };
            })
        }.width('100%').margin({ bottom: 8 })

        Row() {
          Text('冲突阈值')
            .fontSize(13).fontColor('#333').layoutWeight(1)
          TextInput({ text: '' + this.config.conflictThreshold })
            .width(80).fontSize(13)
            .onChange((v: string) => {
              this.config = {
                incRetainCount: this.config.incRetainCount,
                deepRetainCount: this.config.deepRetainCount,
                paradigmRetainCount: this.config.paradigmRetainCount,
                residentLayerMaxChars: this.config.residentLayerMaxChars,
                conflictThreshold: parseInt(v, 10) || 5,
                paradigmSubmoduleMax: this.config.paradigmSubmoduleMax,
                modelMode: this.config.modelMode,
                warnTimeCost: this.config.warnTimeCost,
              };
            })
        }.width('100%').margin({ bottom: 8 })

        Button('保存参数配置')
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .width('100%')
          .height(40)
          .margin({ top: 12 })
          .onClick(() => { this.saveAppConfig(); })
      }
      .width('100%')
      .padding(12)
    }
    .width('92%')
    .layoutWeight(1)
    .padding({ bottom: 12 })
  }

  @Builder
  BackupView() {
    Column() {
      Button('导出全库备份')
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor('#FFFFFF')
        .width('100%')
        .height(44)
        .margin({ bottom: 16 })
        .onClick(() => { this.doExport(); })

      Text('已导出的备份文件：')
        .fontSize(13)
        .fontColor('#666')
        .margin({ bottom: 8 })

      if (this.backupFiles.length === 0) {
        Text('（暂无备份）')
          .fontSize(13)
          .fontColor('#999')
      } else {
        Scroll() {
          Column() {
            ForEach(this.backupFiles, (f: string) => {
              Text(f)
                .fontSize(12)
                .fontColor('#333')
                .padding(8)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .width('100%')
                .margin({ bottom: 4 })
            }, (f: string) => f)
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('92%')
    .layoutWeight(1)
    .padding({ bottom: 12 })
  }

  @Builder
  LogView() {
    Scroll() {
      Text(this.autorunlogText.length > 0 ? this.autorunlogText : '（暂无运行日志）')
        .fontSize(12)
        .fontColor('#333')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
    }
    .width('92%')
    .layoutWeight(1)
    .padding({ bottom: 12 })
  }
}
