import { FTRUMGlobalManager } from '@guancecloud/ft_sdk';
import { FTLogger } from '@guancecloud/ft_sdk';
import { Status } from '@guancecloud/ft_sdk';

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
    const startTime: number = Date.now();
    return (): void => {
      const duration: number = (Date.now() - startTime) * 1000000;
      FTRUMGlobalManager.getInstance().addAction(actionName, actionType, duration);
    };
  }
}
