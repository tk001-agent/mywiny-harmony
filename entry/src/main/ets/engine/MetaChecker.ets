import { ModelClient } from './ModelClient';
import { Constants } from '../common/Constants';

export interface CheckResult {
  passed: boolean;
  confidence: number;
  reason: string;
}

export class MetaChecker {
  private modelClient: ModelClient;
  private blacklist: string[];

  constructor(modelClient: ModelClient) {
    this.modelClient = modelClient;
    this.blacklist = ['错误', '不对', '应该', '必须否定', '不正确', '用户错了'];
  }

  checkByKeyword(content: string): boolean {
    for (let i = 0; i < this.blacklist.length; i++) {
      if (content.includes(this.blacklist[i])) {
        return false;
      }
    }
    return true;
  }

  async checkBySemantic(metaCurrent: string, metaBase: string): Promise<CheckResult> {
    let systemPrompt = '你是元理解基准自检器。以下是不不可突破的底层铁律：\n' + metaBase +
      '\n请判断以下元理解内容是否突破上述铁律。只回答JSON格式：{"passed":true/false,"confidence":0-100,"reason":"简短说明"}';
    let userPrompt = '待检查的元理解内容：\n' + metaCurrent;
    let resp = await this.modelClient.chatWithSystem(systemPrompt, userPrompt);
    if (!resp.success) {
      return { passed: true, confidence: 50, reason: '语义校验 API 调用失败，跳过: ' + resp.error };
    }
    return this.parseCheckResult(resp.content);
  }

  async check(metaCurrent: string, metaBase: string): Promise<CheckResult> {
    if (!this.checkByKeyword(metaCurrent)) {
      return { passed: false, confidence: 100, reason: '关键词黑名单过滤未通过' };
    }
    let semantic = await this.checkBySemantic(metaCurrent, metaBase);
    if (semantic.confidence < Constants.META_CONFIDENCE_THRESHOLD) {
      return {
        passed: false,
        confidence: semantic.confidence,
        reason: '语义校验置信度低于 ' + Constants.META_CONFIDENCE_THRESHOLD + '%: ' + semantic.reason,
      };
    }
    return semantic;
  }

  private parseCheckResult(content: string): CheckResult {
    let jsonStr = content.trim();
    let braceStart = jsonStr.indexOf('{');
    let braceEnd = jsonStr.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      jsonStr = jsonStr.substring(braceStart, braceEnd + 1);
    }
    try {
      let obj = JSON.parse(jsonStr) as CheckJson;
      return {
        passed: obj.passed === true,
        confidence: obj.confidence !== undefined ? obj.confidence : 50,
        reason: obj.reason !== undefined ? obj.reason : '',
      };
    } catch (e) {
      return { passed: true, confidence: 50, reason: '语义校验结果解析失败，默认通过' };
    }
  }
}

interface CheckJson {
  passed?: boolean;
  confidence?: number;
  reason?: string;
}
