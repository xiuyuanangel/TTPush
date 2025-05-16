import { notificationManager } from '@kit.NotificationKit';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { appInfoManager } from '@kit.StoreKit';
import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME = 'TTPushSettings';
const TOKEN_KEY = 'userToken';

// 通知消息的数据结构
class NotificationMessage {
  id: number;
  title: string;
  content: string;
  time: string;
  isRead: boolean;

  constructor(id: number, title: string, content: string, time: string, isRead: boolean = false) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.time = time;
    this.isRead = isRead;
  }
}

interface NotificationParams {
  updatedNotification:NotificationMessage;
}

@Entry
@Component
struct Index {
  private prefs: preferences.Preferences | null = null;
  @State notifications: NotificationMessage[] = [];
  @State isRefreshing: boolean = false;
  @State test: string = 'test';
  private scroller: ListScroller = new ListScroller();
  @StorageLink('colorMode') @Watch('colorModeChange') colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  @State token: string = '';
  @StorageLink('pushToken') @Watch('pushTokenChange') pushToken: string = '';

  // 获取保存的usertoken
  async getToken() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const preferencesInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
      const value = await preferencesInstance.get(TOKEN_KEY, '');
      this.token = value.toString();
    } catch (error) {
      console.error(`Failed to get token: ${error}`);
    }
  }

  @Builder itemEnd(notification: NotificationMessage) {
    Button(){
      Image('images/Delete.png')
        .width('100px')
        .height('100px')
    }
    .margin('4vp')
    .backgroundColor(this.colorMode ? '#FFFFFF' : '#000000')
    .onClick(async () => {
      let index = this.notifications.indexOf(notification);
      this.notifications.splice(index, 1);
      await this.saveNotifications();
      this.scroller.closeAllSwipeActions();
    })
  }

  // 加载保存的通知
  async loadNotifications() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
      const saved = await this.prefs.get('notifications', '[]') as string;
      // this.test = saved;
      const parsed: NotificationMessage[] = JSON.parse(saved);
      if (Array.isArray(parsed)) {
        this.notifications = parsed.map(n => new NotificationMessage(
          n.id, 
          n.title, 
          n.content, 
          n.time, 
          n.isRead
        ));
      }
    } catch (err) {
      console.error('Failed to load notifications:', err);
    }
  }
  
  // 保存通知到本地
  async saveNotifications() {
    if (this.prefs) {
      try {
        await this.prefs.put('notifications', JSON.stringify(this.notifications));
        await this.prefs.flush();

      } catch (err) {
        console.error('Failed to save notifications:', err);
      }
    }
  }
  // 获取当前时间，格式化为 YYYY-MM-DD HH:MM
  getCurrentTime(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  async onPageShow() {
    // 检查是否有从详情页返回的更新通知
    const params: NotificationParams = router.getParams() as NotificationParams;
    if (params && params.updatedNotification) {
      const updatedNotification = params.updatedNotification;
      // 更新通知列表中的通知状态
      const index = this.notifications.findIndex(n => n.id === updatedNotification.id);
      if (index !== -1) {
        this.notifications[index].isRead = updatedNotification.isRead;
        // 触发界面更新
        this.notifications = [...this.notifications];
      }
      await this.saveNotifications();
    }
  }

  // 处理通知点击
  async handleNotificationClick(notification: NotificationMessage) {
    // 跳转到通知详情页
    let index = this.notifications.indexOf(notification);
    this.notifications[index].isRead = true;
    this.notifications = [...this.notifications];
    notification.isRead = true;
    await this.saveNotifications();

    router.pushUrl({
      url: 'pages/NotificationDetail',
      params: notification
    });
  }

  async aboutToAppear() {
    await this.loadNotifications();
    // 刷新通知列表
    this.isRefreshing = true;
    // 页面加载时读取已保存的token
    this.getToken();
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('通知')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()

        Image( this.colorMode ? 'images/Setting_icon.png' : 'images/Setting_icon_dark2.png')
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' })
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      
      // 通知列表
      Refresh({ refreshing: $$this.isRefreshing, offset: 120, friction: 100 }) {
        if (this.notifications.length === 0) {
          Column() {
            Text('📭')
              .fontSize(60)
              .margin({ bottom: 16 })
            
            Text('暂无通知')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 8, scroller: this.scroller }) {
            ForEach(this.notifications, (notification: NotificationMessage) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Row() {
                    Text(notification.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .margin({ bottom: 4 })
                      .alignSelf(ItemAlign.Start)
                      .fontColor('#000000')
                    
                    if (!notification.isRead) {
                      Badge({
                        value: '',
                        position: BadgePosition.Right,
                        style: { color: '#FF0000', fontSize: 6 }
                      })
                      .margin({ left: 8 })
                    }
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Start)
                  
                  Text(notification.content.length > 10 ? notification.content.substring(0, 10) + '...' : notification.content)
                    .fontSize(14)
                    .fontColor('#666666')
                    .alignSelf(ItemAlign.Start)
                }
                .layoutWeight(1)
                
                Row() {
                  Text(notification.time)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ right: 8 })
                }
                .justifyContent(FlexAlign.End)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(notification.isRead ? '#FFFFFF' : '#F5F5F5')
            .onClick(() => this.handleNotificationClick(notification))
            .borderRadius(8)
          }
          // .margin({bottom: 5})
          .border({
            width: 1,
            color: Color.Grey,
            radius: 8
          })
          .swipeAction({
            end: {
              builder: () => { this.itemEnd(notification) },
              onAction: () => {
                this.getUIContext()?.animateTo({ duration: 1000 }, async () => {
                  let index = this.notifications.indexOf(notification);
                  this.notifications.splice(index, 1);
                  await this.saveNotifications();
                });
              },
              actionAreaDistance: '70vp' // 滑动距离
            }
          })
            })
          }
          .padding({left:8, right:8})
          .width('100%')
          .layoutWeight(1)
          // .backgroundColor('#FF0000')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .onRefreshing(() => {
        // 模拟刷新操作
        setTimeout(async () => {
          await this.getToken();
          if (this.token === ''){
            this.isRefreshing = false;
            return;
          }

          let httpRequest = http.createHttp();
          httpRequest.request(
            `https://xt.jianglidev.com/ttpush/notifications?pushToken=${this.pushToken}&usertoken=${this.token}`,
            {
              method: http.RequestMethod.GET,
            }, async (err: Error, data: http.HttpResponse) => {
            if (!err) {
              const result: NotificationMessage[] = JSON.parse(data.result.toString());
              if (result.length > 0) {
                this.notifications = [...result, ...this.notifications];
                await this.saveNotifications();
              }
            }
          })
          this.isRefreshing = false;
        }, 1000);
      })
      // Text(JSON.stringify(this.notifications))
    }
    .width('100%')
    .height('100%')
  }

  colorModeChange(changedPropertyName: string) {
  }

  pushTokenChange(changedPropertyName: string) {
  }
}