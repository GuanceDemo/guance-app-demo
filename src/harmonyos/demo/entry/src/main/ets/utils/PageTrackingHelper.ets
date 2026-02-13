import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

/**
 * Page tracking helper
 * Provides consistent page tracking across all pages
 */
export class PageTrackingHelper {
  /**
   * Track page appearance
   * Call this in aboutToAppear() lifecycle method
   */
  static trackPageAppear(pageName: string): void {
    FTRUMGlobalManager.getInstance().startView(pageName);
    FTLogger.logBackground(`${pageName} appeared`, Status.INFO);
  }

  /**
   * Track page disappearance
   * Call this in aboutToDisappear() lifecycle method
   */
  static trackPageDisappear(): void {
    FTRUMGlobalManager.getInstance().stopView();
  }

  /**
   * Track user action
   */
  static trackAction(actionName: string, actionType: string = 'click'): void {
    FTRUMGlobalManager.getInstance().addAction(actionName, actionType);
  }

  /**
   * Track action with start/stop
   * Returns a function to stop the action
   */
  static trackActionWithTiming(actionName: string, actionType: string = 'click'): () => void {
    FTRUMGlobalManager.getInstance().startAction(actionName, actionType);
    return () => FTRUMGlobalManager.getInstance().stopAction();
  }
}
