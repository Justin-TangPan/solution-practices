import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.tests.checks import security, tf_syntax


TF = '''
terraform { required_providers { huaweicloud = { source = "huawei.com/provider/huaweicloud" } } }
provider "huaweicloud" { region = "cn-north-4" }
resource "huaweicloud_compute_instance" "ecs" {
  user_data = <<-EOF
    #!/bin/bash
    echo ok
  EOF
}
'''


class QualityGateTest(unittest.TestCase):
    def fixture(self, *texts):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        (root / "terraform").mkdir()
        for index, text in enumerate(texts):
            (root / "terraform" / f"deploying-demo{index}.tf").write_text(text)
        self.addCleanup(tmp.cleanup)
        return root

    def test_requires_one_parseable_template(self):
        self.assertFalse([result for result in tf_syntax.run(self.fixture(TF), {}) if not result.passed])
        results = tf_syntax.run(self.fixture(TF, TF), {})
        self.assertTrue(any(not result.passed and "只有一个" in result.message for result in results))

    def test_blocks_public_http_control_plane(self):
        exposed = TF + '''
resource "huaweicloud_networking_secgroup_rule" "web" {
  ports = 4000
  remote_ip_prefix = "0.0.0.0/0"
}
output "dashboard" { value = "http://example.invalid master_key" }
'''
        results = security.run(self.fixture(exposed), {})
        self.assertTrue(any(not result.passed and "公网 HTTP" in result.message for result in results))

    def test_warns_for_confirmed_public_http_exception(self):
        exposed = TF + '''
resource "huaweicloud_networking_secgroup_rule" "web" {
  ports = 4000
  remote_ip_prefix = "0.0.0.0/0"
}
output "dashboard" { value = "http://example.invalid master_key" }
'''
        config = {"quality_gate": {"architecture_exceptions": {
            "demo/*/standard": {"accepted_risks": ["public_http_control_plane"]}
        }}}
        entry = {"name": "demo", "site": "cn", "region": "test", "deploy_type": "standard"}
        with patch.object(security, "load_project_config", return_value=config):
            results = security.run(self.fixture(exposed), entry)
        self.assertTrue(any(result.passed and result.severity == "WARN"
                            and "已确认架构例外" in result.message for result in results))

    def test_allows_confirmed_provider_set(self):
        ha = TF.replace(
            'huaweicloud = { source = "huawei.com/provider/huaweicloud" }',
            'huaweicloud = { source = "huawei.com/provider/huaweicloud" } '
            'kubernetes = { source = "hashicorp/kubernetes" }',
        )
        config = {"quality_gate": {"architecture_exceptions": {
            "demo/*/ha": {"allowed_providers": ["huaweicloud", "kubernetes"]}
        }}}
        entry = {"name": "demo", "site": "cn", "region": "test", "deploy_type": "ha"}
        with patch.object(tf_syntax, "load_project_config", return_value=config):
            results = tf_syntax.run(self.fixture(ha), entry)
        self.assertFalse([result for result in results if not result.passed])

    def test_blocks_hardcoded_key_and_public_database(self):
        exposed = TF + '''
resource "huaweicloud_networking_secgroup_rule" "db" {
  ports = 5432
  remote_ip_prefix = "0.0.0.0/0"
}
resource "x" "secret" { master_key = "abcdefghijklmnop" }
'''
        results = security.run(self.fixture(exposed), {})
        self.assertTrue(any(not result.passed and "硬编码" in result.message for result in results))
        self.assertTrue(any(not result.passed and "5432" in result.message for result in results))

    def test_allows_environment_credential_reference(self):
        referenced = TF + '''
resource "x" "config" { content = "master_key: os.environ/LITELLM_MASTER_KEY" }
'''
        results = security.run(self.fixture(referenced), {})
        self.assertFalse(any(not result.passed and "硬编码" in result.message for result in results))


if __name__ == "__main__":
    unittest.main()
