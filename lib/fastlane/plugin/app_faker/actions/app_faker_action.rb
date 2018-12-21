require 'fastlane/action'
require_relative '../helper/app_faker_helper'

module Fastlane
  module Actions
    class AppFakerAction < Action
      def self.run(params)
        # 脚本路径
        exec_dir = params[:exec_dir]
        # 项目路径
        proj_dir = params[:proj_dir]
        # 原项目名
        old_name = params[:proj_old_name]
        # 新项目名
        new_name = params[:proj_new_name]
        # 原类名前缀
        old_prefix = params[:class_old_prefix]
        # 新类名前缀
        new_prefix = params[:class_new_prefix]
        # spam输出文件路径
        spam_dir = params[:spam_code_dir]
        # spam代码字符串
        spam_str = params[:spam_code_str]
        # 忽略的文件夹名集合
        ignores = params[:ignore_dir]
        # 是否处理图片资源
        is_handle = params[:handle_xassets]

        # 检查脚本文件的路径
        if !exec_dir || !exec_dir.empty?
          # 默认存放脚本文件的路径
          tmp_dir = File.dirname(__FILE__).gsub!(/\/fastlane\/actions\Z/, "\/exec\/")
          if File::directory?(tmp_dir)
            Dir::entries(tmp_dir).each do |file|
              if File::file?(tmp_dir + file)
                exec_dir = tmp_dir + file
              end
            end
          end
        end

        # 项目根路径
        root_dir = /(.+)\/[a-zA-Z0-9_-]+\.xcodeproj/.match(proj_dir)[1]

        # 待执行的命令
        cmd = "#{exec_dir} #{root_dir}"

        if !exec_dir || exec_dir.empty?
          UI.user_error!("No exec dir for AppFakerAction given, pass using `exec_dir: 'xxx'`")
          return
        end

        # 修改项目名
        if new_name && !new_name.empty?
          regex = /([a-zA-Z0-9_-]+)\.xcodeproj/
          if !old_name || old_name.empty?
            regex.match(proj_dir)
            old_name = $1
          end
          if old_name && !old_name.empty?
            UI.message("替换项目名中...")
            arg = " -modifyProjectName \'#{old_name}>#{new_name}\'"
            tmp = "#{cmd} #{new_name}#{arg}"
            tmp = cmd + '/' + old_name + ' ' + arg
            Actions.sh(tmp)

            # 项目名替换后，需要更新项目路径
            proj_dir.gsub!(regex, "#{new_name}.xcodeproj")
          end
        end


        # 修改类名前缀
        if old_prefix && !old_prefix.empty? && new_prefix && !new_prefix.empty?
          UI.message("替换类名前缀中...")
          arg = " -modifyClassNamePrefix #{proj_dir} \'#{old_prefix}>#{new_prefix}\'"
          if ignores && !ignores.empty?
            arg += " -ignoreDirNames \'#{ignores}\'"
          end
          Actions.sh(cmd + arg)
        end

        # 处理图片资源
        if is_handle
          UI.message("处理图片资源中...")
          # 找到xcassets文件夹
          assets_dir = ''
          dir1 = root_dir + "\/Assets.xcassets"
          dir2 = root_dir + '/' + new_name + "\/Assets.xcassets"
          if File::exist?(dir1)
            assets_dir = dir1
          elsif File::exist?(dir2)
            assets_dir = dir2
          end

          if assets_dir.empty?
            # 没有找到xcassets文件夹，则以项目根路径作为处理
            assets_dir = ''
          end

          # 重命名图片文件
          arg = " -handleXcassets"
          Actions.sh(exec_dir + " " + assets_dir + arg)

          # 压缩图片
          Actions.sh('find ' + assets_dir + ' -iname "*.png" -exec echo {} \; -exec convert {} {} \;')
        end

        # 生成混淆文件
        if spam_str && !spam_str.empty?
          if !spam_dir
            # 默认混淆文件的路径
            spam_dir = File.dirname(__FILE__).gsub!(/\/fastlane\/actions\Z/, "\/spam\/")
          end
          # 文件夹是否存在
          if !File::exist?(spam_dir)
            # 创建文件夹
            Dir::mkdir(spam_dir)
          end
          # 删除文件夹下可能存在的文件
          Dir::entries(spam_dir).each do |file|
            if File::file?(spam_dir + file)
              File::delete(spam_dir + file)
            end
          end

          UI.message("生成混淆文件中...")
          arg = " -spamCodeOut #{spam_dir} \'#{spam_str}\'"
          if ignores && !ignores.empty?
            arg += " -ignoreDirNames \'#{ignores}\'"
          end
          tmp = cmd + '/' + new_name + ' ' + arg
          Actions.sh(tmp)
        end
      end

      def self.description
        "快捷执行代码混淆命令的action"
      end

      def self.authors
        ["Carefree"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "You can use this action to do cool things..."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :proj_dir,
                                       description: "Xcode项目文件路径，即xxx.xcodeproj文件的绝对路径",
                                       verify_block: proc do |value|
                                          UI.user_error!("No Xcode project dir for AppFakerAction given, pass using `proj_dir: 'xxx.xcodeproj'`") unless (value and not value.empty?)
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :exec_dir,
                                       description: "混淆脚本的文件路径",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :proj_old_name,
                                       description: "原项目名",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :proj_new_name,
                                       description: "重命名的项目名",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :class_old_prefix,
                                       description: "原类名前缀",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :class_new_prefix,
                                       description: "新类名前缀",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :spam_code_dir,
                                       description: "垃圾代码输出的文件夹路径",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :spam_code_str,
                                       description: "插入的垃圾代码字符串",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :ignore_dir,
                                       description: "忽略处理的文件夹名，多个路径可用 `,` 分隔",
                                       optional:true,# 选填
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :handle_xassets,
                                       description: "是否处理图片名称及hash",
                                       optional:true,# 选填
                                       is_string: false),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        
        platform == :ios
      end
    end
  end
end
