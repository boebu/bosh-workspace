require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:release) do
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo",
        name_version: "foo/1", manifest_file: "releases/foo-1.yml")
    end
    let(:stemcell) do
      instance_double("Bosh::Workspace::Stemcell",
        name: "bar", version: "2", name_version: "bar/2",
        file: ".stemcesll/bar-2.tgz", file_name: "bar-2.tgz")
    end

    before do
      allow(command).to receive(:require_project_deployment)
      allow(command).to receive(:auth_required)
      allow(command).to receive(:project_deployment_releases)
        .and_return(releases)
      allow(command).to receive(:project_deployment_stemcells)
        .and_return(stemcells)
    end

    describe "prepare_release(s/_repos)" do
      let(:releases) { [ release ] }
      let(:stemcells) { [] }

      before do
        expect(release).to receive(:update_repo) 
        expect(command).to receive(:release_uploaded?)
          .with(release.name, release.version).and_return(release_uploaded)
      end

      context "release uploaded" do
        let(:release_uploaded) { true }

        it "does not upload the release" do
          expect(command).to_not receive(:release_upload)
          command.prepare
        end
      end

      context "release not uploaded" do
        let(:release_uploaded) { false }

        it "does not upload the release" do
          expect(command).to receive(:release_upload).with(release.manifest_file)
          command.prepare
        end
      end
    end

    describe "prepare_stemcells" do
      let(:releases) { [] }
      let(:stemcells) { [ stemcell ] }

      before do
        expect(command).to receive(:stemcell_uploaded?)
          .with(stemcell.name, stemcell.version).and_return(stemcell_uploaded)
      end

      context "stemcell uploaded" do
        let(:stemcell_uploaded) { true }

        it "does not upload the stemcell" do
          expect(command).to_not receive(:stemcell_download)
          expect(command).to_not receive(:stemcell_upload)
          command.prepare
        end
      end

      context "stemcell not uploaded" do
        let(:stemcell_uploaded) { false }

        before do 
          allow(stemcell).to receive(:downloaded?)
            .and_return(stemcell_downloaded)
        end

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { true }

          it "does not upload the stemcell" do
            expect(command).to_not receive(:stemcell_download)
            expect(command).to receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { false }

          it "does not upload the stemcell" do
            expect(command).to receive(:stemcell_download).with(stemcell.file_name)
            expect(command).to receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end
      end
    end
  end
end
