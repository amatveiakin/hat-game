import nltk
import re
from difflib import SequenceMatcher
from nltk.metrics import edit_distance

nltk.download("punkt", quiet=True)


class RussianCognateDetector:
    def __init__(self, similarity_threshold: float = 0.5):
        self.similarity_threshold = similarity_threshold

    def check_word(self, word: str) -> bool:
        return bool(re.match(r"^[а-яёА-ЯЁ-]+$", word))

    def normalize_word(self, word: str) -> str:
        return word.lower()

    # TODO: Check each metric!
    def calculate_similarity(self, word1: str, word2: str) -> float:
        """
        Calculate linguistic similarity between two Russian words.

        Uses multiple metrics:
        1. Sequence matcher ratio
        2. Edit distance ratio
        3. Common prefix/suffix length

        Returns:
            float: Similarity score between 0 and 1
        """
        assert self.check_word(word1), f"Invalid word: {word1}"
        assert self.check_word(word2), f"Invalid word: {word2}"

        norm_word1 = self.normalize_word(word1)
        norm_word2 = self.normalize_word(word2)

        # Sequence matcher similarity
        seq_matcher = SequenceMatcher(None, norm_word1, norm_word2)
        seq_ratio = seq_matcher.ratio()

        # Edit distance similarity
        max_len = max(len(norm_word1), len(norm_word2))
        edit_dist = edit_distance(norm_word1, norm_word2)
        edit_ratio = 1 - (edit_dist / max_len)

        # Common prefix/suffix length
        match = seq_matcher.find_longest_match(0, len(norm_word1), 0, len(norm_word2))
        prefix_len = match.size
        prefix_ratio = prefix_len / max_len

        # Weighted average of similarity metrics
        similarity = (seq_ratio + edit_ratio + prefix_ratio) / 3

        return similarity

    def is_cognate(self, word1: str, word2: str) -> bool:
        similarity = self.calculate_similarity(word1, word2)
        return similarity >= self.similarity_threshold


def main():
    # Example usage
    detector = RussianCognateDetector()

    test_cases = [
        ("стол", "столик"),
        ("дом", "домик"),
        ("книга", "читать"),
        ("ночь", "нощный"),
        ("рука", "руководство"),
        ("яблоко", "яблочный"),
        ("яблоко", "груша"),
        ("лес", "лесник"),
        ("лес", "лесной"),
        ("лес", "лесничий"),
        ("лес", "лесополоса"),
        ("дуб", "ясень"),
        ("дуб", "желудь"),
        ("водопой", "водитель"),
    ]

    for word1, word2 in test_cases:
        similarity = detector.calculate_similarity(word1, word2)
        is_cognate = detector.is_cognate(word1, word2)
        print(
            f"{word1:>12} & {word2:12}: Similarity = {similarity:.2f}, Cognates: {is_cognate}"
        )


if __name__ == "__main__":
    main()
