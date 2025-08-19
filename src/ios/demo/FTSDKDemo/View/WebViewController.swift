//
//  WebViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import WebKit
class WebViewController: UIViewController,WKNavigationDelegate,WKUIDelegate {
    var webView:WKWebView!
    var progressView: UIProgressView!
    var website = NetworkEngine.shared.webView

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .navigationBackgroundColor
        title = "WebView"
        createUI()
    }
    func createUI(){
        webView = WKWebView()
//        if #available(iOS 16.4, *) {
//            webView.isInspectable=true
//        } 
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let top = self.navigationController?.navigationBar.frame.maxY ?? 0
        webView.frame = CGRect(x: 0, y: top, width: self.view.bounds.width, height: self.view.frame.height-top)
        view.addSubview(webView)
        
        let url = URL(string: website)!
        webView.backgroundColor = .navigationBackgroundColor
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 0, y: top, width: self.view.bounds.width, height: 5)
        view.addSubview(progressView)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = Float(webView.estimatedProgress)
            progressView.progress = progress
            if progress == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {[weak self] in
                    self?.progressView.isHidden = true
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))
        self.present(alert, animated: true)
    }
  
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
