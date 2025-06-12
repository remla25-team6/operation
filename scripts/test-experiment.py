import requests
import urllib3
import matplotlib.pyplot as plt
import numpy as np

URL = "https://192.168.56.92/"

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class sample_request:
    
    def __init__(self, URL, pr=0.05):
        self.URL = URL
        self.pr=pr
        self.cached_payload = "Some review to analyse that will be re-submitted with some probability"
        self.non_cached_payload = 1 # To ensure that no duplicates are used instead if wanted, this integer is incremented in every new request that DOESNT have a chaced hit.
        self.headerv1 = {
        'x-version': "v1"
        }
        self.headerv2 = {
        'x-version': "v2"
        }

        # Some variables to keep track of the state
        self.requests_sent = 0
        self.requests_v1 = 0
        self.requests_v2 = 0
        self.cached_sent_v1 = 0
        self.cached_sent_v2 = 0
    
    def send_with_prob(self):
        # This assumes a 50/50 probability split between v1/v2 for convinience
        # Probability here refers to the probability that a cached input is provided (default = 5 percent)
        alpha = np.random.random()
        pr_repeat = np.random.random()
        if alpha > 0.5:
            self.requests_v1 += 1
            r = self.send_v1(repeat=(self.pr > pr_repeat))
        else:
            self.requests_v2 += 1
            r = self.send_v2(repeat=(self.pr > pr_repeat))
        self.requests_sent += 1

        return (alpha > 0.5), (self.pr > pr_repeat), r
        
    def send_v1(self, repeat=False):
        if not repeat:
            self.non_cached_payload += 1
        else:
            self.cached_sent_v1 += 1
        data = {
            'review': (str(self.non_cached_payload) if (not repeat) else self.cached_payload)
            }
        return requests.post(self.URL, headers=self.headerv1, data=data, verify=False)
    
    def send_v2(self, repeat=False):
        if not repeat:
            self.non_cached_payload += 1
        else:
            self.cached_sent_v2 += 1
        data = {
            'review': (str(self.non_cached_payload) if (not repeat) else self.cached_payload)
            }
        return requests.post(self.URL, headers=self.headerv2, data = data, verify=False)
        
    def run_experiment(self, number_of_requests):
        for i in range (number_of_requests):
            was_v1, was_cached, res = self.send_with_prob()
            print((bcolors.OKGREEN if was_v1 else bcolors.OKBLUE) + f"Sent a request to: {"v1" if was_v1 else "v2"} with a {"cached" if was_cached else "non_cached"} input" + bcolors.ENDC)

        print(bcolors.OKCYAN + f"Sent {self.requests_sent} total requests" + bcolors.ENDC)
        print(bcolors.OKCYAN + f"Sent {self.requests_v1} requests to V1 of which {self.cached_sent_v1} were repeat inputs" + bcolors.ENDC)
        print(bcolors.OKCYAN + f"Sent {self.requests_v2} requests to V2 of which {self.cached_sent_v2} were repeat inputs" + bcolors.ENDC)

        print(bcolors.OKCYAN + f"There was a 50% chance between v1/v2 and a probability of {self.pr} to repeat an input" + bcolors.ENDC)
    

def run():
    req = sample_request(URL, pr=0.05)
    req.run_experiment(500)





if __name__ == "__main__":
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    run()
