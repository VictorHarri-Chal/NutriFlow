require "active_storage/service/s3_service"

# Extends the S3 service to:
# - Namespace all blobs under a configurable key_prefix (e.g. "storage") so they
#   don't pile up at the bucket root alongside unrelated folders (backups/, etc.).
# - Generate public CDN URLs pointing to cdn.nutriflow.in instead of the R2 API
#   endpoint, so images are served directly from Cloudflare's edge.
#
# Uploads (writes) still go through the R2 API endpoint (S3_ENDPOINT).
# config/storage.yml options: cdn_host, key_prefix.
class ActiveStorage::Service::CloudflareR2Service < ActiveStorage::Service::S3Service
  def initialize(cdn_host: nil, key_prefix: nil, **options)
    super(**options)
    @cdn_host   = cdn_host
    @key_prefix = key_prefix
  end

  private

  def object_for(key)
    bucket.object(prefixed(key))
  end

  def public_url(key, filename: nil)
    @cdn_host ? "#{@cdn_host}/#{prefixed(key)}" : super
  end

  def prefixed(key)
    @key_prefix ? "#{@key_prefix}/#{key}" : key
  end
end
