const API_URL = [
  {
    'groupId': 'pzc1',
    'groupName': 'hackmunmun',
    'score': 3,
    'members': [
      {
        'name': 'Game',
        'address': '0xxaabb'
      },
      {
        'name': 'Tot',
        'address': '0xxaacc'
      },
      {
        'name': 'Bank',
        'address': '0xxaaee'
      }
    ]
  },
  {
    'groupId': 'pzc2',
    'groupName': 'hacknooknook',
    'score': 3,
    'members': [
      {
        'name': 'Game',
        'address': '0xxaaff'
      },
      {
        'name': 'Tot',
        'address': '0xxaagg'
      },
      {
        'name': 'Bank',
        'address': '0xxaahh'
      }
    ]
  },
  {
    'groupId': 'pzc3',
    'groupName': 'hackborbor',
    'score': 3,
    'members': [
      {
        'name': 'Sittiphol',
        'address': '0xxaaii'
      },
      {
        'name': 'Zent',
        'address': '0xxaakk'
      },
      {
        'name': 'Phuwanai',
        'address': '0xxaall'
      }
    ]
  }
]

export default {
  async getProposal () {
    // const res = await fetch(API_URL)
    const res = API_URL
    // return res.json()
    return res
  }
}
