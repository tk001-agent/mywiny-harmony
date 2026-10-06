import { router } from '@kit.ArkUI';
import { AppContext } from '../common/AppContext';
import { TopicNode, ProjectNode } from '../model/DataTypes';

@Entry
@Component
struct KnowledgePage {
  @State currentTab: number = 0;
  @State topicText: string = '';
  @State projectText: string = '';
  @State conflictText: string = '';
  @State changelogText: string = '';
  private appCtx: AppContext = AppContext.getInstance();
  private tabs: string[] = ['话题树', '项目树', '冲突归档', '变更日志'];

  aboutToAppear(): void {
    this.refreshAll();
  }

  refreshAll(): void {
    this.refreshTopics();
    this.refreshProjects();
    this.conflictText = this.appCtx.treeStorage.readConflictArchive();
    this.changelogText = this.appCtx.metaStorage.readAutorunlog();
  }

  refreshTopics(): void {
    let topics = this.appCtx.treeStorage.readTopicTree();
    if (topics.length === 0) {
      this.topicText = '（话题树为空，执行进化后将自动生成）';
      return;
    }
    let sb = '';
    for (let i = 0; i < topics.length; i++) {
      let t = topics[i];
      let indent = '';
      for (let j = 1; j < t.level; j++) {
        indent += '  ';
      }
      let mark = t.archived ? '[归档] ' : '';
      sb += indent + '- ' + mark + t.id + ' ' + t.title +
        ' (ref:' + t.refs.join(',') + ')\n';
      if (t.description.length > 0) {
        sb += indent + '    ' + t.description + '\n';
      }
    }
    this.topicText = sb;
  }

  refreshProjects(): void {
    let projects = this.appCtx.treeStorage.readProjectTree();
    if (projects.length === 0) {
      this.projectText = '（项目树为空，执行进化后将自动生成）';
      return;
    }
    let sb = '';
    for (let i = 0; i < projects.length; i++) {
      let p = projects[i];
      sb += '- ' + p.id + ' ' + p.title +
        ' (topics:' + p.topicIds.join(',') + ' ref:' + p.refs.join(',') + ')\n';
      if (p.description.length > 0) {
        sb += '    ' + p.description + '\n';
      }
    }
    this.projectText = sb;
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => { router.back(); })
        Text('知识库')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Row() {
        ForEach(this.tabs, (tab: string, index: number) => {
          Text(tab)
            .fontSize(14)
            .fontColor(this.currentTab === index ? '#FFFFFF' : '#333')
            .backgroundColor(this.currentTab === index ? '#007DFF' : '#EEE')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => { this.currentTab = index; })
        }, (tab: string) => tab)
      }
      .width('92%')
      .margin({ bottom: 12 })

      Scroll() {
        Text(this.getCurrentText())
          .fontSize(13)
          .fontColor('#333')
          .width('100%')
          .padding(12)
          .backgroundColor('#F9F9F9')
          .borderRadius(8)
      }
      .width('92%')
      .layoutWeight(1)
      .padding({ bottom: 12 })
    }
    .height('100%')
    .width('100%')
  }

  getCurrentText(): string {
    if (this.currentTab === 0) {
      return this.topicText;
    } else if (this.currentTab === 1) {
      return this.projectText;
    } else if (this.currentTab === 2) {
      return this.conflictText.length > 0 ? this.conflictText : '（无冲突记录）';
    } else {
      return this.changelogText.length > 0 ? this.changelogText : '（无运行日志）';
    }
  }
}
