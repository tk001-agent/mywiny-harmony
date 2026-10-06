import http from '@ohos.net.http';
import { ModelMessage, ModelResponse } from '../model/DataTypes';
import { FileUtil } from '../storage/FileUtil';
import { DirManager } from '../storage/DirManager';
import { Constants } from '../common/Constants';

export interface ModelApiConfig {
  apiUrl: string;
  apiKey: string;
  modelName: string;
}

export class ModelClient {
  private dirManager: DirManager;
  private config: ModelApiConfig;

  constructor(dirManager: DirManager) {
    this.dirManager = dirManager;
    this.config = { apiUrl: '', apiKey: '', modelName: '' };
    this.loadConfig();
  }

  loadConfig(): void {
    let path = this.dirManager.getAppDir() + '/model_config.json';
    if (!FileUtil.exists(path)) {
      return;
    }
    let text = FileUtil.readText(path);
    try {
      let obj = JSON.parse(text) as ModelApiConfig;
      this.config.apiUrl = obj.apiUrl || '';
      this.config.apiKey = obj.apiKey || '';
      this.config.modelName = obj.modelName || '';
    } catch (e) {
    }
  }

  saveConfig(config: ModelApiConfig): void {
    this.config = config;
    let path = this.dirManager.getAppDir() + '/model_config.json';
    FileUtil.writeText(path, JSON.stringify(config));
  }

  getConfig(): ModelApiConfig {
    return this.config;
  }

  isConfigured(): boolean {
    return this.config.apiUrl.length > 0 && this.config.apiKey.length > 0;
  }

  async chat(messages: ModelMessage[]): Promise<ModelResponse> {
    if (!this.isConfigured()) {
      return { success: false, content: '', error: '模型 API 未配置，请在系统页设置 API 地址和密钥' };
    }
    let httpRequest = http.createHttp();
    try {
      let body = JSON.stringify({
        model: this.config.modelName,
        messages: messages,
        temperature: 0.3,
      });
      let headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + this.config.apiKey,
      };
      let resp = await httpRequest.request(this.config.apiUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: Constants.MODEL_TIMEOUT,
        readTimeout: Constants.MODEL_TIMEOUT,
      });
      let result = resp.result as string;
      let content = this.parseResponse(result);
      return { success: true, content: content, error: '' };
    } catch (e) {
      return { success: false, content: '', error: 'API 请求失败: ' + String(e) };
    } finally {
      httpRequest.destroy();
    }
  }

  async chatWithSystem(systemPrompt: string, userPrompt: string): Promise<ModelResponse> {
    let messages: ModelMessage[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ];
    return this.chat(messages);
  }

  private parseResponse(result: string): string {
    try {
      let obj = JSON.parse(result) as ChatResponse;
      if (obj.choices && obj.choices.length > 0) {
        return obj.choices[0].message.content;
      }
      if (obj.content) {
        return obj.content;
      }
      return result;
    } catch (e) {
      return result;
    }
  }
}

interface ChatResponse {
  choices?: ChatChoice[];
  content?: string;
}

interface ChatChoice {
  message: ChatMessage;
}

interface ChatMessage {
  content: string;
}
