describe Fastlane::Actions::AppFakerAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The app_faker plugin is working!")

      Fastlane::Actions::AppFakerAction.run(nil)
    end
  end
end
