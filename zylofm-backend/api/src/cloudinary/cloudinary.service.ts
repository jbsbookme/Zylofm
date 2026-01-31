import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import * as streamifier from 'streamifier';

export type CloudinaryUploadResult = {
  secureUrl: string;
  publicId: string;
  resourceType: string;
  bytes: number;
};

@Injectable()
export class CloudinaryService {
  private readonly uploadPreset: string | undefined;

  private isPlaceholder(value: string): boolean {
    const v = value.trim().toLowerCase();
    return v.length === 0 || v === 'xxxxx' || v === 'xxxx' || v === 'changeme' || v === 'change_me';
  }

  constructor() {
    const cloudName = (process.env.CLOUDINARY_CLOUD_NAME ?? '').trim();
    const apiKey = (process.env.CLOUDINARY_API_KEY ?? '').trim();
    const apiSecret = (process.env.CLOUDINARY_API_SECRET ?? '').trim();
    const preset = (process.env.CLOUDINARY_UPLOAD_PRESET ?? '').trim();

    this.uploadPreset = preset.length > 0 ? preset : undefined;

    if (this.isPlaceholder(cloudName) || this.isPlaceholder(apiKey) || this.isPlaceholder(apiSecret)) {
      // Fail late: some environments (tests) may not need uploads.
      return;
    }

    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
      secure: true,
    });
  }

  private isPresetNotFoundError(error: unknown): boolean {
    if (!error || typeof error !== 'object') return false;
    const anyErr = error as { message?: unknown; error?: unknown };
    const message = typeof anyErr.message === 'string' ? anyErr.message : '';
    return message.toLowerCase().includes('upload preset') && message.toLowerCase().includes('not found');
  }

  private uploadBufferInternal(params: {
    buffer: Buffer;
    filename: string;
    folder: string;
    resourceType: 'image' | 'video';
    contentType?: string;
    useUploadPreset: boolean;
  }): Promise<CloudinaryUploadResult> {
    return new Promise<CloudinaryUploadResult>((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: params.folder,
          resource_type: params.resourceType,
          filename_override: params.filename,
          use_filename: true,
          unique_filename: true,
          ...(params.useUploadPreset && this.uploadPreset ? { upload_preset: this.uploadPreset } : {}),
        },
        (error, result) => {
          if (error || !result) {
            reject(error ?? new Error('Cloudinary upload failed'));
            return;
          }

          resolve({
            secureUrl: result.secure_url,
            publicId: result.public_id,
            resourceType: result.resource_type,
            bytes: result.bytes,
          });
        },
      );

      streamifier.createReadStream(params.buffer).pipe(uploadStream);
    });
  }

  async uploadBuffer(params: {
    buffer: Buffer;
    filename: string;
    folder: string;
    resourceType: 'image' | 'video';
    contentType?: string;
  }): Promise<CloudinaryUploadResult> {
    const cloudName = (process.env.CLOUDINARY_CLOUD_NAME ?? '').trim();
    const apiKey = (process.env.CLOUDINARY_API_KEY ?? '').trim();
    const apiSecret = (process.env.CLOUDINARY_API_SECRET ?? '').trim();
    const preset = (process.env.CLOUDINARY_UPLOAD_PRESET ?? '').trim();
    if (this.isPlaceholder(cloudName) || this.isPlaceholder(apiKey) || this.isPlaceholder(apiSecret)) {
      throw new Error(
        'Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET in .env (not xxxxx).',
      );
    }

    const hasPreset = !this.isPlaceholder(preset) && !!this.uploadPreset;
    try {
      return await this.uploadBufferInternal({
        buffer: params.buffer,
        filename: params.filename,
        folder: params.folder,
        resourceType: params.resourceType,
        contentType: params.contentType,
        useUploadPreset: hasPreset,
      });
    } catch (error) {
      // If the preset is misconfigured or missing in Cloudinary, fall back to a signed upload.
      if (hasPreset && this.isPresetNotFoundError(error)) {
        return await this.uploadBufferInternal({
          buffer: params.buffer,
          filename: params.filename,
          folder: params.folder,
          resourceType: params.resourceType,
          contentType: params.contentType,
          useUploadPreset: false,
        });
      }
      throw error;
    }
  }
}
