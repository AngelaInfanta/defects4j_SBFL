import json
import sys
import os
from os import path as osp

def backtrack(project, bugId, version):
    d4j_home = os.environ['D4J_HOME']
    config = json.load(open(osp.join(d4j_home,"framework","bin","config.json")))
    backtrack = json.load(open(osp.join(config['FAULT_DIR'],project+"_backtrack.json")))
    bugFix = None
    for bug in backtrack:
        if (bugId in bug["bug"].keys()):
            if (bugId == version):
                bugFix = bug["bug"]
            elif (version in bug):
                bugFix = bug[version]
            break
    if (bugFix == None or bugFix == "failed"):
        return "Bug not found: failed to apply backtrack"
    else:
        bugFix = bugFix[bugId]
        ret = ""
        for file in bugFix:
            ret += file+","+','.join(map(str,bugFix[file]))+"\n"
        return ret[:-1]

if __name__ == "__main__":
    project = sys.argv[1]
    bugId = sys.argv[2]
    version = sys.argv[3]
    print(backtrack(project, bugId, version))
