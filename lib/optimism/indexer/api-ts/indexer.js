export * from './generated';
const createQueryString = ({ cursor, limit }) => {
    if (cursor === undefined && limit === undefined) {
        return '';
    }
    const queries = [];
    if (cursor) {
        queries.push(`cursor=${cursor}`);
    }
    if (limit) {
        queries.push(`limit=${limit}`);
    }
    return `?${queries.join('&')}`;
};
export const depositEndpoint = ({ baseUrl = '', address, cursor, limit }) => {
    return [baseUrl, 'deposits', `${address}${createQueryString({ cursor, limit })}`].join('/');
};
export const withdrawalEndoint = ({ baseUrl = '', address, cursor, limit }) => {
    return [baseUrl, 'withdrawals', `${address}${createQueryString({ cursor, limit })}`].join('/');
};
