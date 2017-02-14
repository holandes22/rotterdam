var path = require("path");
var webpack = require("webpack");
var merge = require("webpack-merge");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var ExtractTextPlugin = require("extract-text-webpack-plugin");


var common = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [/node_modules/],
        use: "babel-loader",
      },
      {
        test: [/\.scss$/, /\.css$/],
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader!sass-loader"
        })
      },
      {
        test: /\.(png|jpg|gif|svg)$/,
        use: "file-loader?name=/images/[name].[ext]"
      },
      {
        test: /\.(ttf|eot|svg|woff2?)$/,
        use: "file-loader?name=/fonts/[name].[ext]",
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-webpack-loader",
            options: {
              "cwd": path.resolve(__dirname, "web", "elm"),
              "debug": true
            }
          }
        ]
      },
    ],
    noParse: [/\.elm$/]
  },
  // TODO: run this in prod only
  // plugins: [
  //   new webpack.optimize.UglifyJsPlugin({
  //     compress: {warnings: false},
  //     output: {comments: false}
  //   })
  //   })
  // ]
};

module.exports = [
  merge(common, {
    entry: {
      vendor: [
        "normalize.css",
        "font-awesome-loader",
        "flexboxgrid/dist/flexboxgrid.css",
        "webcomponents.js/webcomponents.js",
      ],
      app: [
        "./web/static/app/app.scss",
        "./web/static/app/app.js"
      ]
    },
    output: {
      path: "./priv/static",
      filename: "js/[name].js"
    },
    resolve: {
      modules: [
        "node_modules",
        path.resolve(__dirname, "web", "static", "app")
      ]
    },
    plugins: [
      new webpack.optimize.CommonsChunkPlugin({
        name: "vendor"
      }),
      new CopyWebpackPlugin([{ from: "./web/static/assets" }]),
      new ExtractTextPlugin("css/[name].css")
    ]
  })
];
