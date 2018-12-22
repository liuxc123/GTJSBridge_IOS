Pod::Spec.new do |s|
  s.name             = 'GTJSBridge'
  s.version          = '0.0.1'
  s.summary          = '提供IOS平台WAP页面和客户端本地native插件交互的枢纽框架'
  s.homepage         = 'https://github.com/liuxc123/GTJSBridge'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liuxc123' => 'lxc_work@126.com' }
  s.source           = { :git => 'https://github.com/liuxc123/GTJSBridge.git', :tag => s.version.to_s }
  s.platform              = :ios, '8.0'
  
  # JSService
  s.subspec "JSService" do |component|
      component.ios.deployment_target = '8.0'
      component.public_header_files = 'GTJSBridge/GTJSService/*.h'
      component.source_files = 'GTJSBridge/GTJSService/*.{h,m}'
      
      component.resources = ["GTJSBridge/GTJSService/PluginConfig.json", "GTJSBridge/GTJSService/GTJSBridge.js.txt"]

  end
  
  # Plugins
  s.subspec "Plugins" do |component|
      component.ios.deployment_target = '8.0'
      component.public_header_files = 'GTJSBridge/Plugins/*.h'
      component.source_files = 'GTJSBridge/Plugins/*.{h,m}'
      
      component.dependency "GTJSBridge/JSService"
  end

    
    # WKWebView
    s.subspec "WKWebView" do |component|
        component.ios.deployment_target = '8.0'
        component.public_header_files = 'GTJSBridge/WKWebView/**/*.h'
        component.source_files = 'GTJSBridge/WKWebView/**/*.{h,m}'
        component.resources = ["GTJSBridge/WKWebView/resource/*.bundle"]

        component.dependency "GTJSBridge/Plugins"
        component.dependency "GTUIKit/CommonComponent/Toast"
        component.dependency "GTUIKit/CommonComponent/NavigationController"

        component.dependency "Aspects"
    end

    # WKWebView
    s.subspec "WKWebViewWithGTUINavigationBar" do |component|
        component.ios.deployment_target = '8.0'
        component.public_header_files = 'GTJSBridge/WKWebView/**/*.h'
        component.source_files = 'GTJSBridge/WKWebView/**/*.{h,m}'
        component.resources = ["GTJSBridge/WKWebView/resource/*.bundle"]

        component.dependency "GTJSBridge/Plugins"
        component.dependency "GTUIKit/CommonComponent/Toast"
        component.dependency "GTUIKit/CommonComponent/NavigationController"

        component.dependency "Aspects"
    end

  
end
