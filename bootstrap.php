<?php

declare(strict_types=1);

use App\Models\Setting;
use App\Models\User;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

try {
    if (!Schema::hasTable('users') || !Schema::hasTable('settings')) {
        exit(1);
    }

    $appUrl = rtrim((string) getenv('APP_URL'), '/');
    $companyName = (string) (getenv('PAYMENTER_COMPANY_NAME') ?: 'Paymenter');

    if ($appUrl !== '') {
        Setting::updateOrCreate(['key' => 'app_url'], ['value' => $appUrl]);
    }
    Setting::firstOrCreate(['key' => 'company_name'], ['value' => $companyName]);
    Cache::forget('settings');

    if (User::query()->count() === 0) {
        $email = (string) getenv('PAYMENTER_ADMIN_EMAIL');
        $password = (string) getenv('PAYMENTER_ADMIN_PASSWORD');
        $firstName = (string) (getenv('PAYMENTER_ADMIN_FIRST_NAME') ?: 'Railway');
        $lastName = (string) (getenv('PAYMENTER_ADMIN_LAST_NAME') ?: 'Admin');

        if ($email === '' || $password === '') {
            fwrite(STDERR, "PAYMENTER_ADMIN_EMAIL and PAYMENTER_ADMIN_PASSWORD are required.\n");
            exit(1);
        }

        $status = Artisan::call('app:user:create', [
            'first_name' => $firstName,
            'last_name' => $lastName,
            'email' => $email,
            'password' => $password,
            'role' => 1,
        ]);

        if ($status !== 0) {
            exit($status);
        }

        fwrite(STDOUT, "Created the initial Paymenter administrator.\n");
    }
} catch (Throwable $error) {
    fwrite(STDERR, "Paymenter bootstrap is waiting for migrations: {$error->getMessage()}\n");
    exit(1);
}
