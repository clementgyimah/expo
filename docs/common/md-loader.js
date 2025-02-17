const fm = require('front-matter');

module.exports = function (src) {
  const { body, attributes } = fm(src);

  return (
    `import DocumentationElements from '~/components/page-higher-order/DocumentationElements';

export const meta = ${JSON.stringify(attributes)}

export default DocumentationElements;

` + body
  );
};
