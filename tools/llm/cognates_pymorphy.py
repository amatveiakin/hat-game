import pymorphy3


class RootCognateDetector:
    def __init__(self):
        self.morph = pymorphy3.MorphAnalyzer()

    def get_roots(self, word):
        """
        Extract potential roots from a word's morphological parse
        """
        parses = self.morph.parse(word)
        roots = set()
        for parse in parses:
            # Extract the part of the word that represents the root
            if parse.normal_form:
                roots.add(parse.normal_form)
        return roots

    def are_cognates(self, word1, word2):
        """
        Check if words have at least one common root
        """
        roots1 = self.get_roots(word1)
        roots2 = self.get_roots(word2)

        return len(roots1.intersection(roots2)) > 0


# Example usage
detector = RootCognateDetector()
test_cases = [
    ("дом", "домик"),  # Likely cognates
    ("писать", "писатель"),  # Likely cognates
    ("город", "городской"),  # Likely cognates
    ("книга", "читать"),  # Not cognates
]

for word1, word2 in test_cases:
    result = detector.are_cognates(word1, word2)
    print(f"{word1} & {word2}: Cognates = {result}")
