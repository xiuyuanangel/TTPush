import { router } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';

interface NotificationDetailProps {
    id: number,
    title: string,
    content: string,
    time: string,
    isRead: boolean
  }

@Entry
@Component
struct NotificationDetail {
  @State notification: NotificationDetailProps = router.getParams() as NotificationDetailProps;
  @StorageLink('colorMode') @Watch('colorModeChange') colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←')
          .fontSize(24)
          .margin({ left: 16 })
          .onClick(() => {
            router.back(1,{updatedNotification: this.notification});
          })

        Text('通知详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      Divider()
        .width('100%')
        .color('#DDDDDD')

      // 通知详情内容
      Column() {
        // 标题和时间
        Text(this.notification.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 8 })
          .alignSelf(ItemAlign.Start)

        Text(this.notification.time)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 20 })
          .alignSelf(ItemAlign.Start)

        Divider()
          .width('100%')
          .color('#DDDDDD')
          .margin({ bottom: 20 })

        // 详细内容
        Text(this.notification.content)
          .fontSize(16)
          .fontColor(this.colorMode ? '#333333' : '#CCCCCC')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 20 })

        // 可能的长内容（示例）
        // Text('这是通知的详细内容，可能包含更多信息。通知系统旨在提供重要的更新和提醒，帮助用户及时了解应用的最新动态。')
        //   .fontSize(16)
        //   .fontColor(this.colorMode ? '#333333' : '#CCCCCC')
        //   .alignSelf(ItemAlign.Start)
      }
      .width('90%')
      .padding({ top: 10, bottom: 20 })

      Blank()

      // 底部操作按钮
      Button('标记为未读')
        .width('90%')
        .height(50)
        .margin({ bottom: 20 })
        .backgroundColor(!this.notification.isRead ? '#CCCCCC' : '#007DFF')
        .enabled(this.notification.isRead)
        .onClick(() => {
          // 标记为已读的逻辑
          this.notification.isRead = false;
          // 通知首页更新状态
          router.back(1,{updatedNotification: this.notification});
        })
    }
    .width('100%')
    .height('100%')
  }

  colorModeChange(changedPropertyName: string) {
  }
}
