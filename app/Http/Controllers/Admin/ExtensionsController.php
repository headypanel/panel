<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;
use Pterodactyl\Http\Controllers\Controller;
use ZipArchive;

class ExtensionsController extends Controller
{
    private const DISK = 'local';
    private const DIRECTORY = 'heady-extensions';

    public function index(): View
    {
        $disk = Storage::disk(self::DISK);
        $extensions = collect($disk->allFiles(self::DIRECTORY))
            ->filter(fn (string $path) => str_ends_with($path, '/metadata.json'))
            ->map(function (string $path) use ($disk) {
                try {
                    $data = json_decode($disk->get($path), true, 512, JSON_THROW_ON_ERROR);
                    return is_array($data) ? $data : null;
                } catch (\Throwable $e) {
                    return null;
                }
            })
            ->filter()
            ->sortBy('name')
            ->values();

        return view('admin.extensions.index', ['extensions' => $extensions]);
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'package' => ['required', 'file', 'mimes:zip', 'max:10240'],
        ]);

        $archive = new ZipArchive();
        $file = $request->file('package');
        if ($archive->open($file->getRealPath()) !== true) {
            return back()->withErrors(['package' => 'The uploaded file is not a valid ZIP archive.']);
        }

        try {
            if ($archive->numFiles < 1 || $archive->numFiles > 500) {
                return back()->withErrors(['package' => 'The package must contain between 1 and 500 files.']);
            }

            $manifestStat = $archive->statName('heady-extension.json');
            if ($manifestStat === false || ($manifestStat['size'] ?? PHP_INT_MAX) > 65536) {
                return back()->withErrors(['package' => 'Missing manifest at archive root or manifest exceeds 64 KiB.']);
            }

            $manifestContent = $archive->getFromName('heady-extension.json');
            if ($manifestContent === false) {
                return back()->withErrors(['package' => 'Missing heady-extension.json at the archive root.']);
            }

            try {
                $manifest = json_decode($manifestContent, true, 32, JSON_THROW_ON_ERROR);
            } catch (\JsonException $e) {
                return back()->withErrors(['package' => 'The extension manifest is not valid JSON.']);
            }

            $id = $manifest['id'] ?? '';
            if (!is_string($id) || !preg_match('/^[a-z][a-z0-9-]{2,63}$/', $id)) {
                return back()->withErrors(['package' => 'Manifest id must be 3–64 lowercase letters, numbers, or hyphens and start with a letter.']);
            }
            foreach (['name', 'version', 'description', 'apiVersion'] as $key) {
                if (!isset($manifest[$key]) || !is_string($manifest[$key]) || trim($manifest[$key]) === '') {
                    return back()->withErrors(['package' => "Manifest field '{$key}' is required."]);
                }
            }
            if (!preg_match('/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/', $manifest['version'])) {
                return back()->withErrors(['package' => 'Version must follow semantic versioning.']);
            }

            // Reject traversal paths and symlinks. Packages are stored as inert artifacts;
            // uploading a package never executes its contents.
            for ($i = 0; $i < $archive->numFiles; $i++) {
                $stat = $archive->statIndex($i);
                $name = $stat['name'] ?? '';
                if ($name === '' || str_contains($name, "\\") || str_starts_with($name, '/') ||
                    preg_match('#(^|/)\.\.?(/|$)#', $name) || str_contains($name, "\0")) {
                    return back()->withErrors(['package' => 'Archive contains an unsafe path.']);
                }
                if (($stat['size'] ?? 0) > 20 * 1024 * 1024) {
                    return back()->withErrors(['package' => 'An archive entry exceeds the 20 MiB limit.']);
                }
            }

            $directory = self::DIRECTORY . '/' . $id;
            $existing = $directory . '/metadata.json';
            if (Storage::disk(self::DISK)->exists($existing)) {
                return back()->withErrors(['package' => 'An extension with this id already exists. Remove it before uploading a replacement.']);
            }

            $stored = $file->storeAs($directory, 'package.zip', self::DISK);
            if (!$stored) {
                return back()->withErrors(['package' => 'Could not store the uploaded package.']);
            }

            $metadata = [
                'id' => $id,
                'name' => mb_substr(trim($manifest['name']), 0, 120),
                'version' => $manifest['version'],
                'description' => mb_substr(trim($manifest['description']), 0, 500),
                'apiVersion' => mb_substr(trim($manifest['apiVersion']), 0, 32),
                'enabled' => false,
                'uploadedAt' => now()->toIso8601String(),
                'package' => $stored,
            ];
            Storage::disk(self::DISK)->put($existing, json_encode($metadata, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        } finally {
            $archive->close();
        }

        return redirect()->route('admin.extensions')->with('success', 'Extension package uploaded. It is stored disabled and has not been executed.');
    }

    public function toggle(string $id): RedirectResponse
    {
        if (!preg_match('/^[a-z][a-z0-9-]{2,63}$/', $id)) {
            abort(404);
        }
        $disk = Storage::disk(self::DISK);
        $path = self::DIRECTORY . '/' . $id . '/metadata.json';
        abort_unless($disk->exists($path), 404);

        $metadata = json_decode($disk->get($path), true);
        abort_unless(is_array($metadata) && ($metadata['id'] ?? null) === $id, 404);
        // Enable is a registry state only. No uploaded PHP/JS code is evaluated.
        $metadata['enabled'] = !($metadata['enabled'] ?? false);
        $metadata['updatedAt'] = now()->toIso8601String();
        $disk->put($path, json_encode($metadata, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        return redirect()->route('admin.extensions')->with('success', 'Extension registry state updated. Enabling does not execute package code.');
    }

    public function destroy(string $id): RedirectResponse
    {
        if (!preg_match('/^[a-z][a-z0-9-]{2,63}$/', $id)) {
            abort(404);
        }
        $disk = Storage::disk(self::DISK);
        $directory = self::DIRECTORY . '/' . $id;
        abort_unless($disk->exists($directory . '/metadata.json'), 404);
        $disk->deleteDirectory($directory);

        return redirect()->route('admin.extensions')->with('success', 'Extension package removed.');
    }
}
