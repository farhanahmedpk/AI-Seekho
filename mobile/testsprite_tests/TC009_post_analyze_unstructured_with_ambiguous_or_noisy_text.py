import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_analyze_unstructured_with_ambiguous_or_noisy_text():
    url = f"{BASE_URL}/analyze-unstructured"
    headers = {"Content-Type": "application/json"}

    test_payloads = [
        # Ambiguous but possibly extractable text
        {
            "content": "Driver reported something weird: temp might have hit 42 but not sure on truck alpha.",
            "expect_parsed": True
        },
        # Noisy text with no clear extraction
        {
            "content": "Random words no numbers or identifiers at all, just gibberish and lorem ipsum.",
            "expect_parsed": False
        }
    ]

    for payload in test_payloads:
        response = None
        try:
            response = requests.post(url, json={"content": payload["content"]}, headers=headers, timeout=TIMEOUT)
            assert response.status_code == 200, f"Expected 200 OK but got {response.status_code}"

            json_resp = response.json()
            # The UnstructuredAnalysisResult should at least have fields indicating extraction success or failure
            # We'll check if it contains parsed truck_id and temperature to judge success or failure

            truck_id = json_resp.get("truck_id")
            temperature = json_resp.get("temperature")
            extraction_status = json_resp.get("extraction_status") or json_resp.get("status")  # fallback key if present

            if payload["expect_parsed"]:
                # Expect that extraction succeeded with at least one extracted value
                assert (truck_id is not None) or (temperature is not None), (
                    "Expected extraction of truck_id or temperature but got none."
                )
                # If extraction_status present, it should indicate success
                if extraction_status is not None:
                    assert extraction_status.lower() in ["success", "parsed", "extracted", "ok"], (
                        f"Unexpected extraction_status value: {extraction_status}"
                    )
            else:
                # Expect that extraction failed or no values extracted
                assert (truck_id is None and temperature is None) or (
                    extraction_status and extraction_status.lower() in ["failure", "failed", "unable", "error"]
                ), "Expected extraction to fail or indicate inability, but it appears to have succeeded."

        except requests.exceptions.RequestException as e:
            assert False, f"Request failed: {e}"
        except ValueError:
            assert False, "Response content could not be decoded as JSON"
        finally:
            if response is not None:
                response.close()

test_post_analyze_unstructured_with_ambiguous_or_noisy_text()