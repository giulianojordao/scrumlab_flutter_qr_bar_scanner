Pod::Spec.new do |s|
  s.name             = 'scrumlab_flutter_qr_bar_scanner'
  s.version          = '0.0.1'
  s.summary          = "A Plugin for reading/scanning QR & Bar codes using Google's Mobile Vision API"
  s.description      = <<-DESC
A Plugin for reading/scanning QR & Bar codes using Google's Mobile Vision API.
                       DESC
  s.homepage         = 'https://github.com/contactlutforrahman/scrumlab_flutter_qr_bar_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lutfor Rahman' => 'contact.lutforrahman@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '10.0'

  s.dependency 'GoogleMLKit/BarcodeScanning'

  s.static_framework = true
end
