import { router } from '@kit.ArkUI';
import { AppContext } from '../common/AppContext';
import { SnapshotMeta } from '../model/DataTypes';
import { FileUtil } from '../storage/FileUtil';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct SnapshotPage {
  @State snapshots: SnapshotMeta[] = [];
  @State toastMsg: string = '';
  private appCtx: AppContext = AppContext.getInstance();

  aboutToAppear(): void {
    this.refreshList();
  }

  refreshList(): void {
    this.snapshots = this.appCtx.snapshotManager.listSnapshots();
  }

  doRollback(snapshotId: string): void {
    promptAction.showDialog({
      title: '确认回滚',
      message: '将话题树、项目树、元理解恢复到快照 ' + snapshotId + ' 的状态。\n原始对话和变更日志不受影响。确认继续？',
      buttons: [
        { text: '取消', color: '#666' },
        { text: '确认回滚', color: '#007DFF' },
      ]
    }).then((result) => {
      if (result.index === 1) {
        let ok = this.appCtx.snapshotManager.rollback(snapshotId);
        if (ok) {
          this.showToast('已回滚到 ' + snapshotId);
        } else {
          this.showToast('回滚失败：快照不存在');
        }
      }
    });
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
        Text('快照管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text('共 ' + this.snapshots.length + ' 份')
          .fontSize(12)
          .fontColor('#888')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.snapshots.length === 0) {
        Column() {
          Text('暂无快照')
            .fontSize(16)
            .fontColor('#999')
          Text('执行进化后将自动生成快照')
            .fontSize(12)
            .fontColor('#BBB')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.snapshots, (s: SnapshotMeta) => {
            ListItem() {
              Column() {
                Row() {
                  Text(s.id)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                  Text(s.type === 'deep' ? '深度进化' : '普通进化')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .backgroundColor(s.type === 'deep' ? '#FF6B35' : '#007DFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .margin({ left: 8 })
                }
                .width('100%')

                Text(FileUtil.formatTime(s.timestamp))
                  .fontSize(11)
                  .fontColor('#999')
                  .margin({ top: 4 })

                if (s.note.length > 0) {
                  Text(s.note)
                    .fontSize(12)
                    .fontColor('#666')
                    .margin({ top: 4 })
                }

                Button('回滚到此版本')
                  .type(ButtonType.Capsule)
                  .backgroundColor('#FFF')
                  .fontColor('#007DFF')
                  .border({ width: 1, color: '#007DFF' })
                  .width(120)
                  .height(32)
                  .margin({ top: 8 })
                  .onClick(() => { this.doRollback(s.id); })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 8 })
            }
          }, (s: SnapshotMeta) => s.id)
        }
        .width('92%')
        .layoutWeight(1)
        .padding({ bottom: 12 })
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
}
