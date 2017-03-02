class RSpecDocCombiner
  def self.combine!
    new.combine_children_into_parents
  end

  def combine_children_into_parents
    files.map(&:combine!)
  end

  def files
    @files ||= parent_folders.map do |folder_name|
      fetch_files_for_folder(folder_name)
    end
  end

  def parent_folders
    @parent_folders ||= fetch_parent_folders
  end

  private

  def base_path
    Rails.root.join('doc/api')
  end

  def fetch_files_for_folder(folder_name)
    parent_filepath    = "#{base_path}/#{folder_name}/index.html.md"
    children_filepaths = Dir["#{base_path}/#{folder_name}/**/*.md"].reject do |path|
      path == parent_filepath
    end.sort

    parent = DocFile.new(parent_filepath, parent: true)
    children_filepaths.each { |path| parent.add_child(DocFile.new(path)) }

    parent
  end

  def fetch_parent_folders
    Dir
      .entries(base_path)
      .select { |dir| !invalid_folder_names.include?(dir) }
  end

  def invalid_folder_names
    [
      '.',
      '..',
      '.DS_Store',
      '_generated_examples.markdown',
      'index.html.md'
    ]
  end

  class DocFile
    attr_reader :children, :path

    def initialize(path, parent: false)
      @children = []
      @combined = false
      @parent   = parent
      @path     = path
    end

    def <<(additional_file)
      file << additional_file.read
    end

    def add_child(child)
      children << child
    end

    def close
      file.close
    end

    def combine!
      return self if combined?

      children.each do |child|
        self << child
      end

      @combined = true

      self
    end

    def combined?
      @combined
    end

    def parent?
      @parent
    end

    def read
      @read ||= file.read
    end

    def file
      @file ||= File.open(path, 'a+')
    end

    private

    def after_initialize
      raise ArgumentError, "No file at: #{path}" unless File.exist?(path)
    end
  end
end
