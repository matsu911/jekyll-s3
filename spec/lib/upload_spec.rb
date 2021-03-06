require 'spec_helper'

describe Jekyll::S3::Uploader do
  context '#upload_file' do
    describe 'reduced redundancy setting' do
      let(:config) {
        { 's3_reduced_redundancy' => true }
      }

      it 'allows storing a file under the Reduced Redundancy Storage' do
        file_to_upload = 'index.html'
        s3_client = create_verifying_s3_client(file_to_upload) do |s3_object|
          s3_object.should_receive(:write).with(
            anything(),
            :content_type => 'text/html',
            :reduced_redundancy => true
          )
        end
        Jekyll::S3::Uploader.send(:upload_file,
                                  file_to_upload,
                                  s3_client,
                                  config,
                                  'features/support/test_site_dirs/my.blog.com/_site')
      end
    end

    describe 'content type resolving' do
      let(:config) {
        { 's3_reduced_redundancy' => false }
      }

      it 'adds the content type of the uploaded CSS file into the S3 object' do
        file_to_upload = 'css/styles.css'
        s3_client = create_verifying_s3_client(file_to_upload) do |s3_object|
          s3_object.should_receive(:write).with(
            anything(),
            :content_type => 'text/css',
            :reduced_redundancy => false
          )
        end
        Jekyll::S3::Uploader.send(:upload_file,
                                  file_to_upload,
                                  s3_client,
                                  config,
                                  'features/support/test_site_dirs/my.blog.com/_site')
      end

      it 'adds the content type of the uploaded HTML file into the S3 object' do
        file_to_upload = 'index.html'
        s3_client = create_verifying_s3_client(file_to_upload) do |s3_object|
          s3_object.should_receive(:write).with(
            anything(),
            :content_type => 'text/html',
            :reduced_redundancy => false
          )
        end
        Jekyll::S3::Uploader.send(:upload_file,
                                  file_to_upload,
                                  s3_client,
                                  config,
                                  'features/support/test_site_dirs/my.blog.com/_site')
      end
    end

    def create_verifying_s3_client(file_to_upload, &block)
      def create_objects(file_to_upload, &block)
        def create_html_s3_object(file_to_upload, &block)
          s3_object = stub('s3_object')
          yield s3_object
          s3_object
        end
        objects = {}
        objects[file_to_upload] = create_html_s3_object(file_to_upload, &block)
        objects
      end
      def create_bucket(file_to_upload, &block)
        bucket = stub('bucket')
        bucket.stub(:objects => create_objects(file_to_upload, &block))
        bucket
      end
      buckets = stub('buckets')
      buckets.stub(:[] => create_bucket(file_to_upload, &block))
      s3 = stub('s3')
      s3.stub(:buckets => buckets)
      s3
    end
  end

  context '#load_all_local_files' do
    let(:files) {
      Jekyll::S3::Uploader.send(:load_all_local_files,
                                'spec/sample_files/hyde_site/_site')
    }

    it 'loads regular files' do
      files.should include('css/styles.css')
      files.should include('index.html')
    end

    it 'loads also dotfiles' do
      files.should include('.vimrc')
    end
  end
end
