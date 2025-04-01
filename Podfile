# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

# 禁用资源复制脚本
install! 'cocoapods', :disable_input_output_paths => true, :generate_multiple_pod_projects => true, :preserve_pod_file_structure => true

target 'gourmet-ios' do
  # 使用静态库而不是动态框架
  use_frameworks! :linkage => :static

  # Pods for gourmet-ios
  pod 'Alamofire', '~> 5.7.1'  # 更新到与 turing-ios 相同的版本
  pod 'SwiftyJSON', '~> 5.0'

  target 'gourmet-iosTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'gourmet-iosUITests' do
    # Pods for testing
  end

end

# 添加 post_install 配置
post_install do |installer|
  # 禁用资源脚本
  installer.pods_project.targets.each do |target|
    target.build_phases.each do |build_phase|
      if build_phase.respond_to?(:name) && build_phase.name.include?('Copy') && build_phase.name.include?('Resources')
        target.build_phases.delete(build_phase)
      end
    end
  end

  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    
    # 添加安全相关设置
    config.build_settings['ENABLE_BITCODE'] = 'NO'
    config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
    config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
    config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    
    # 禁用资源复制脚本
    config.build_settings['COPY_PHASE_STRIP'] = 'NO'
    config.build_settings['RESOURCES_TARGETED_DEVICE_FAMILY'] = 'none'
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  end
  
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        
        # 禁用资源复制脚本
        config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
        
        # 禁用资源复制
        config.build_settings['SKIP_INSTALL'] = 'YES'
        config.build_settings['RESOURCES_TARGETED_DEVICE_FAMILY'] = 'none'
        
        # 添加沙盒相关设置
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
