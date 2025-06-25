'use strict';

const { Contract } = require('fabric-contract-api');

    class LandContract extends Contract {

        async InitLedger(ctx) {
        const sampleRequests = [
            {
                id: 'REQ001',
                name: 'Ramu',
                village: 'Kuppam',
                status: 'Submitted',
                createdAt: '2025-06-25T10:00:00.000Z'
            },
            {
                id: 'REQ002',
                name: 'Sita',
                village: 'Tirupati',
                status: 'Under Review',
                createdAt: '2025-06-25T10:00:00.000Z'
            }
        ];

        for (const request of sampleRequests) {
            await ctx.stub.putState(request.id, Buffer.from(JSON.stringify(request)));
            console.info(`Added request: ${request.id}`);
        }

        console.info('✅ Ledger initialized with sample data');
    }


    async createRequest(ctx, id, name, village, status) {
        const exists = await ctx.stub.getState(id);
        if (exists && exists.length > 0) {
            throw new Error(`Request ${id} already exists`);
        }

        const request = {
            id,
            name,
            village,
            status,
            createdAt: new Date().toISOString(),
        };

        await ctx.stub.putState(id, Buffer.from(JSON.stringify(request)));
        return JSON.stringify(request);
    }

    async getRequest(ctx, id) {
        const data = await ctx.stub.getState(id);
        if (!data || data.length === 0) {
            throw new Error(`No request found with ID ${id}`);
        }
        return data.toString();
    }

    async updateStatus(ctx, id, newStatus) {
        const data = await ctx.stub.getState(id);
        if (!data || data.length === 0) {
            throw new Error(`Request ${id} not found`);
        }

        const request = JSON.parse(data.toString());
        request.status = newStatus;
        request.updatedAt = new Date().toISOString();

        await ctx.stub.putState(id, Buffer.from(JSON.stringify(request)));
        return JSON.stringify(request);
    }

    async getAllRequests(ctx) {
        const iterator = await ctx.stub.getStateByRange('', '');
        const allResults = [];

        while (true) {
            const res = await iterator.next();
            if (res.value && res.value.value.toString()) {
                const record = JSON.parse(res.value.value.toString());
                allResults.push(record);
            }
            if (res.done) {
                await iterator.close();
                break;
            }
        }

        return JSON.stringify(allResults);
    }
}

module.exports = LandContract;
