#!/usr/bin/python

class FilterModule(object):
    def filters(self):
        return {'expand_pvs': self.expand_pvs}

    def expand_pvs(self, pvs):
        '''pvs is a list of dicts describing PVs where size is the size of the
        PV, and number is the number of PVs of that size to create.

        Return a generator of (name, size) where name is pv-$size-$index, and
        index is in the range 0 to the number of PVs to create.
        '''
        for pv in pvs:
            for i in range(0, pv['number']):
                size = pv['size']
                shared = pv.get('shared', False)

                name = "pv-%03d-%03d" % (size, i)
                if shared:
                    name += "-shared"

                yield (name, size, shared)
