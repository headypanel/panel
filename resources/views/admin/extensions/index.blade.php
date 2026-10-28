@extends('layouts.admin')

@section('title')
    Extension Manager
@endsection

@section('content-header')
    <h1>Extension Manager <small>Upload and manage HeadyPanel packages.</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Extensions</li>
    </ol>
@endsection

@section('content')
<div class="row">
    <div class="col-xs-12">
        @if (session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif
        @if ($errors->any())
            <div class="alert alert-danger"><ul class="m-b-0">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
        @endif
        <div class="alert alert-warning">
            <strong>Security notice:</strong> uploaded packages are stored as inert ZIP files. This manager does not execute extension code or install server-side hooks. Only upload packages from sources you trust.
        </div>
        <div class="box box-primary">
            <div class="box-header with-border"><h3 class="box-title">Upload extension package</h3></div>
            <form method="POST" action="{{ route('admin.extensions.store') }}" enctype="multipart/form-data">
                @csrf
                <div class="box-body">
                    <p>Choose a ZIP containing <code>heady-extension.json</code> at its root. Maximum upload size: 10 MiB.</p>
                    <div class="form-group">
                        <label for="package">Extension ZIP</label>
                        <input id="package" type="file" name="package" accept=".zip,application/zip" class="form-control" required>
                    </div>
                </div>
                <div class="box-footer"><button type="submit" class="btn btn-primary">Upload package</button></div>
            </form>
        </div>
        <div class="box">
            <div class="box-header with-border"><h3 class="box-title">Installed packages</h3></div>
            <div class="box-body table-responsive no-padding">
                <table class="table table-hover">
                    <thead><tr><th>Name</th><th>ID</th><th>Version</th><th>API</th><th>Status</th><th>Actions</th></tr></thead>
                    <tbody>
                    @forelse ($extensions as $extension)
                        <tr>
                            <td><strong>{{ $extension['name'] ?? 'Unknown' }}</strong><br><small>{{ $extension['description'] ?? '' }}</small></td>
                            <td><code>{{ $extension['id'] ?? '' }}</code></td>
                            <td>{{ $extension['version'] ?? '' }}</td>
                            <td>{{ $extension['apiVersion'] ?? '' }}</td>
                            <td><span class="label {{ ($extension['enabled'] ?? false) ? 'label-success' : 'label-default' }}">{{ ($extension['enabled'] ?? false) ? 'Enabled (registry only)' : 'Disabled' }}</span></td>
                            <td>
                                @if (!empty($extension['id']))
                                    <form method="POST" action="{{ route('admin.extensions.toggle', ['id' => $extension['id']]) }}" style="display:inline">
                                        @csrf
                                        <button class="btn btn-xs btn-default" type="submit">{{ ($extension['enabled'] ?? false) ? 'Disable' : 'Enable' }}</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.extensions.destroy', ['id' => $extension['id']]) }}" style="display:inline" onsubmit="return confirm('Remove this extension package?')">
                                        @csrf @method('DELETE')
                                        <button class="btn btn-xs btn-danger" type="submit">Remove</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="text-center text-muted">No extension packages uploaded yet.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
