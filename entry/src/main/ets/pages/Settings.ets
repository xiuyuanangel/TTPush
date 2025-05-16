import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { pushService } from '@kit.PushKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';

const PREFERENCES_NAME = 'TTPushSettings';
const TOKEN_KEY = 'userToken';

interface APIResponse {
  code: number;
  msg: string;
}

@Entry
@Component
struct Settings {
  @State token: string = '';
  
  aboutToAppear() {
    // 页面加载时读取已保存的token
    this.getToken();
  }
  
  // 获取保存的token
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
  
  // 保存token
  async saveToken(token: string) {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const preferencesInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
      await preferencesInstance.put(TOKEN_KEY, token);
      await preferencesInstance.flush();
      promptAction.showToast({ message: 'Token已保存' });
    } catch (error) {
      console.error(`Failed to save token: ${error}`);
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .margin({ left: 16 })
          .onClick(() => {
            router.back()
          })

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      Divider()
        .width('100%')
        .color('#E3E3E3')

      // Token输入区域
      Column() {
        Text('Token设置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ top: 20, bottom: 8 })
        
        TextInput({ text: this.token, placeholder: '请输入您的Token' })
          .type(InputType.Normal)
          .placeholderColor('#999999')
          .placeholderFont({ size: 14 })
          .caretColor('#007DFF')
          .width('100%')
          .height(40)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.token = value;
          })
        
        Button('保存')
          .width(120)
          .height(40)
          .margin({ top: 16 })
          .onClick(() => {
            if (this.token.trim() === '') {
              promptAction.showToast({ message: 'Token不能为空' });
              return;
            }
            //获取pushToken
            pushService.getToken()
              .then((pushToken) => {
                let httpRequest = http.createHttp();
                httpRequest.request(
                  `https://xt.jianglidev.com/ttpush?pushToken=${pushToken}&usertoken=${this.token}`,
                  {
                    method: http.RequestMethod.GET,
                  }, (err: Error, data: http.HttpResponse) => {
                  if (!err) {
                    console.info('Result:' + JSON.stringify(data.result));
                    const result: APIResponse = JSON.parse(data.result.toString());
                    if (result.msg === 'success') {
                      this.saveToken(this.token);

                      //获取通知权限
                      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                      notificationManager.isNotificationEnabled().then((data: boolean) => {
                        if(!data){
                          notificationManager.requestEnableNotification(context).then(() => {
                            console.log(`[ANS] requestEnableNotification success`);
                            router.back();
                          })
                        } else {
                          router.back();
                        }
                      });

                      // setTimeout(() => {
                      //   router.back()
                      // }, 500);
                      // router.back();
                    } else {
                      promptAction.showToast({ message: `设置失败：${result.msg}`});
                    }
                  } else {
                    promptAction.showToast({ message: `设置失败：${JSON.stringify(err)}`});
                  }
                })
              })
              .catch((err: BusinessError) => {
                promptAction.showToast({ message: `发送失败：${err.message}`});
              });
          })
      }
      .width('90%')
      .margin(20)
    }
    .width('100%')
    .height('100%')
  }
}
