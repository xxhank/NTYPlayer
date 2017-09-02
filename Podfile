# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'
inhibit_all_warnings!

target 'NTYPlayer' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!
  # Pods for NTYPlayer
  pod 'libextobjc/EXTScope'
  pod 'libextobjc/EXTKeyPathCoding'
  pod 'CocoaLumberjack'
  pod 'UIColor-Utilities'
  pod 'RealReachability'
  pod 'OpenUDID'
  pod 'KeychainItemWrapper-Copy'
  pod 'Masonry'

  pod 'UITableView+FDTemplateLayoutCell'
  pod 'YYDispatchQueuePool'
  pod "JRSwizzle", :git=>"https://github.com/rentzsch/jrswizzle.git", :branch=>"semver-1.x"

  pod 'FBMemoryProfiler', :configurations => ['Debug']

  target 'NTYPlayerTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'NTYPlayerUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
