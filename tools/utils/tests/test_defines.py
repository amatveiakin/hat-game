from tools.utils.defines import REPO_ROOT


def test_repo_root():
    assert REPO_ROOT.exists()
    assert (REPO_ROOT / ".git").exists()
