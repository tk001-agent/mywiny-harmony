export interface RawDialog {
  id: string;
  content: string;
  timestamp: number;
}

export interface TopicNode {
  id: string;
  title: string;
  parentId: string;
  level: number;
  refs: string[];
  activeWeight: number;
  archived: boolean;
  description: string;
}

export interface ProjectNode {
  id: string;
  title: string;
  topicIds: string[];
  refs: string[];
  description: string;
}

export type SnapshotType = 'inc' | 'deep';

export interface SnapshotMeta {
  id: string;
  type: SnapshotType;
  timestamp: number;
  note: string;
}

export interface ConflictSolution {
  label: string;
  description: string;
  confidence: number;
  content: string;
}

export interface ConflictRecord {
  id: string;
  topicId: string;
  severity: number;
  description: string;
  solutions: ConflictSolution[];
  chosenLabel: string;
  refs: string[];
  resolved: boolean;
}

export interface MetaInfo {
  version: number;
  content: string;
  confidence: number;
  timestamp: number;
  needReview: boolean;
}

export type SubModuleStatus = 'active' | 'dormant';

export interface ParadigmSubModule {
  name: string;
  scene: string;
  coreModel: string;
  dimensions: string[];
  effect: string;
  refs: string[];
  activity: number;
  status: SubModuleStatus;
}

export interface EvolutionSummary {
  mode: string;
  newDialogCount: number;
  newTopicCount: number;
  newProjectCount: number;
  conflictCount: number;
  snapshotId: string;
  duration: number;
  success: boolean;
  message: string;
}

export interface AppConfig {
  incRetainCount: number;
  deepRetainCount: number;
  paradigmRetainCount: number;
  residentLayerMaxChars: number;
  conflictThreshold: number;
  paradigmSubmoduleMax: number;
  modelMode: string;
  warnTimeCost: number;
}

export interface ModelMessage {
  role: string;
  content: string;
}

export interface ModelResponse {
  success: boolean;
  content: string;
  error: string;
}

export interface TreeData {
  topics: TopicNode[];
  projects: ProjectNode[];
}

export const DEFAULT_CONFIG: AppConfig = {
  incRetainCount: 5,
  deepRetainCount: 5,
  paradigmRetainCount: 5,
  residentLayerMaxChars: 2000,
  conflictThreshold: 5,
  paradigmSubmoduleMax: 30,
  modelMode: 'api',
  warnTimeCost: 300,
};
