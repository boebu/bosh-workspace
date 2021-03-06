module Bosh::Workspace
  class ManifestBuilder
    include Bosh::Workspace::SpiffHelper

    def self.build(project_deployment, work_dir)
      manifest_builder = ManifestBuilder.new(project_deployment, work_dir)
      manifest_builder.merge_templates
    end

    def initialize(project_deployment, work_dir)
      @project_deployment = project_deployment
      @work_dir = work_dir
    end

    def merge_templates
      spiff_merge spiff_template_paths, @project_deployment.merged_file
    end

    private

    def spiff_template_paths
      spiff_templates = template_paths
      spiff_templates << stub_file_path
    end

    def template_paths
      @project_deployment.templates.map { |t| template_path(t) }
    end

    def stub_file_path
      path = hidden_file_path(:stubs)
      StubFile.create(path, @project_deployment)
      path
    end

    def hidden_file_path(type)
      File.join(hidden_dir_path(type), "#{@project_deployment.name}.yml")
    end

    def hidden_dir_path(name)
      dir = File.join(@work_dir, ".#{name.to_s}")
      Dir.mkdir(dir) unless File.exists? dir
      dir
    end

    # TODO move to template validator which should have access to @work_dir
    def template_path(template)
      path = File.join(@work_dir, "templates", template)
      err("Template does not exist: #{template}") unless File.exists? path
      path
    end
  end
end
