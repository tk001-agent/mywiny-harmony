import { router } from '@kit.ArkUI';
import { AppContext } from '../common/AppContext';
import { RawDialog } from '../model/DataTypes';
import { FileUtil } from '../storage/FileUtil';

@Entry
@Component
struct RawDialogPage {
  @State inputText: string = '';
  @State searchText: string = '';
  @State dialogs: RawDialog[] = [];
  @State selectedContent: string = '';
  @State selectedId: string = '';
  @State showDetail: boolean = false;
  @State toastMsg: string = '';
  private appCtx: AppContext = AppContext.getInstance();

  aboutToAppear(): void {
    this.refreshList();
  }

  refreshList(): void {
    this.dialogs = this.appCtx.rawStorage.listDialogs();
  }

  saveDialog(): void {
    let content = this.inputText.trim();
    if (content.length === 0) {
      this.showToast('请输入对话内容');
      return;
    }
    let id = this.appCtx.rawStorage.appendDialog(content);
    this.inputText = '';
    this.refreshList();
    this.showToast('已保存 ' + id);
  }

  doSearch(): void {
    let kw = this.searchText.trim();
    if (kw.length === 0) {
      this.refreshList();
      return;
    }
    this.dialogs = this.appCtx.rawStorage.searchDialogs(kw);
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
        Text('原始对话')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text('共 ' + this.dialogs.length + ' 条')
          .fontSize(12)
          .fontColor('#888')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      TextArea({ placeholder: '录入原始想法...' })
        .width('92%')
        .height(100)
        .fontSize(14)
        .margin({ bottom: 8 })
        .onChange((value: string) => { this.inputText = value; })

      Button('保存对话')
        .type(ButtonType.Capsule)
        .backgroundColor('#007DFF')
        .fontColor('#FFFFFF')
        .width('92%')
        .height(40)
        .margin({ bottom: 12 })
        .onClick(() => { this.saveDialog(); })

      Row() {
        TextInput({ placeholder: '关键词搜索' })
          .width('70%')
          .fontSize(14)
          .onChange((value: string) => { this.searchText = value; })
        Button('搜索')
          .type(ButtonType.Capsule)
          .backgroundColor('#666')
          .fontColor('#FFFFFF')
          .width(70)
          .height(36)
          .margin({ left: 8 })
          .onClick(() => { this.doSearch(); })
      }
      .width('92%')
      .margin({ bottom: 12 })

      List() {
        ForEach(this.dialogs, (d: RawDialog) => {
          ListItem() {
            Column() {
              Row() {
                Text(d.id)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#007DFF')
                Text(FileUtil.formatTime(d.timestamp))
                  .fontSize(11)
                  .fontColor('#999')
                  .margin({ left: 8 })
              }
              .width('100%')
              Text(d.content.length > 60 ? d.content.substring(0, 60) + '...' : d.content)
                .fontSize(13)
                .fontColor('#333')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ bottom: 6 })
            .onClick(() => {
              this.selectedId = d.id;
              this.selectedContent = d.content;
              this.showDetail = true;
            })
          }
        }, (d: RawDialog) => d.id)
      }
      .width('92%')
      .layoutWeight(1)
      .padding({ bottom: 12 })

      if (this.toastMsg.length > 0) {
        Text(this.toastMsg)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#333')
          .padding(8)
          .borderRadius(4)
          .position({ x: '50%', y: '90%' })
      }

      if (this.showDetail) {
        Column() {
          Text(this.selectedId)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })
          Scroll() {
            Text(this.selectedContent)
              .fontSize(14)
              .fontColor('#333')
          }
          .layoutWeight(1)
          .width('100%')
          Button('关闭')
            .type(ButtonType.Capsule)
            .backgroundColor('#666')
            .fontColor('#FFFFFF')
            .width(100)
            .height(36)
            .margin({ top: 12 })
            .onClick(() => { this.showDetail = false; })
        }
        .width('100%')
        .height('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .position({ x: 0, y: 0 })
      }
    }
    .height('100%')
    .width('100%')
  }
}
