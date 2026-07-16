import io
import unittest
from types import SimpleNamespace

from scripts.obs.upload import archive_name, download_bytes, obs_key


class CurrentSdkClient:
    def getObject(self, bucket, key, loadStreamInMemory=False):
        assert loadStreamInMemory is True
        body = SimpleNamespace(buffer=b"current-sdk")
        return SimpleNamespace(status=200, body=body)


class LegacySdkClient:
    def getObject(self, bucket, key, **kwargs):
        if "loadStreamInMemory" in kwargs:
            raise TypeError("unexpected keyword")
        assert kwargs == {"loadStreamInMS": True}
        body = SimpleNamespace(response=io.BytesIO(b"legacy-sdk"))
        return SimpleNamespace(status=200, body=body)


class ObsUploadTests(unittest.TestCase):
    def test_cn_key_contains_site(self):
        self.assertEqual(
            obs_key("supabase", "cn-north-4", "standard", "0.9.1.1", "manifest.json", site="cn"),
            "sac/supabase/cn/cn-north-4/standard/0.9.1.1/manifest.json",
        )

    def test_intl_keys_are_locale_aware(self):
        en_key = obs_key(
            "supabase", "ap-southeast-1", "standard", "0.9.1.1", "manifest.json", site="intl", locale="en-us"
        )
        zh_key = obs_key(
            "supabase", "ap-southeast-1", "standard", "0.9.1.1", "manifest.json", site="intl", locale="zh-cn"
        )
        self.assertNotEqual(en_key, zh_key)
        self.assertIn("/intl/en-us/", en_key)
        self.assertIn("/intl/zh-cn/", zh_key)

    def test_archive_name_contains_locale(self):
        self.assertEqual(
            archive_name("supabase", "0.9.1.1", "ap-southeast-1", "standard", site="intl", locale="en-us"),
            "supabase-0.9.1.1-intl-en-us-ap-southeast-1-standard.zip",
        )

    def test_download_uses_current_sdk_argument(self):
        self.assertEqual(download_bytes(CurrentSdkClient(), "bucket", "key"), b"current-sdk")

    def test_download_falls_back_to_legacy_sdk_argument(self):
        self.assertEqual(download_bytes(LegacySdkClient(), "bucket", "key"), b"legacy-sdk")


if __name__ == "__main__":
    unittest.main()
