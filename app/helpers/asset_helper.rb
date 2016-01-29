module AssetHelper
  def find_asset(name)
    app = Rails.application
    if app.assets
      app.assets.find_asset(name)
    else
      app.assets_manifest.assets[name]
    end
  end

  def asset_source(name)
    asset = find_asset(name)
    if asset.is_a?(Sprockets::Asset)
      asset.source
    elsif asset
      path = File.join(Rails.root, 'public', Rails.application.config.assets.prefix, asset)
      File.read(path)
    end
  end
end